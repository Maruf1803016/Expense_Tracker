import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';

enum TransactionMode {
  expense,
  income,
  plan,
}

class PlannedTransactionEntry {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String? subCategory;
  final String? subCategoryIcon;

  PlannedTransactionEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.subCategory,
    this.subCategoryIcon,
  });
}

class AddExpensePage extends StatefulWidget {
  final Expense? expenseToEdit;
  final String? preselectedPlanId;
  final String? preselectedCategoryId;

  const AddExpensePage({
    super.key,
    this.expenseToEdit,
    this.preselectedPlanId,
    this.preselectedCategoryId,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _tagsController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  TransactionMode _mode = TransactionMode.expense;
  String? _selectedSubCategoryName;
  String? _selectedSubCategoryIcon;
  String? _selectedPlanId;

  // Plan mode specific fields
  DateTime _planStartDate = DateTime.now();
  DateTime _planEndDate = DateTime.now().add(const Duration(days: 30));
  List<String> _planSelectedCategoryIds = [];

  // Plan inline mini-form entries
  final List<PlannedTransactionEntry> _plannedEntries = [];
  bool _showAddTransactionForm = false;
  bool _isSaving = false;
  late TextEditingController _miniAmountController;
  late TextEditingController _miniDescriptionController;
  String? _miniSelectedCategoryId;
  String? _miniSelectedSubCategoryName;
  String? _miniSelectedSubCategoryIcon;

  // Two-step flow fields
  int _currentStep = 1;
  String _amountString = '';
  bool _isRecurring = false;
  bool _isGoalContribution = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expenseToEdit?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expenseToEdit?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.expenseToEdit?.note ?? '',
    );
    _tagsController = TextEditingController();
    _miniAmountController = TextEditingController();
    _miniDescriptionController = TextEditingController();
    _selectedCategoryId = widget.preselectedCategoryId ?? widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    
    if (widget.expenseToEdit != null) {
      _mode = widget.expenseToEdit!.type == CategoryType.income
          ? TransactionMode.income
          : TransactionMode.expense;
      _amountString = widget.expenseToEdit!.amount.toString();
      if (_amountString.endsWith('.0')) {
        _amountString = _amountString.substring(0, _amountString.length - 2);
      }
    } else {
      _mode = TransactionMode.expense;
    }
    
    _selectedSubCategoryName = widget.expenseToEdit?.subCategory;
    _selectedSubCategoryIcon = widget.expenseToEdit?.subCategoryIcon;
    _selectedPlanId = widget.preselectedPlanId ?? widget.expenseToEdit?.planId;
    _isGoalContribution = _selectedPlanId != null;
    
    if (widget.preselectedCategoryId != null) {
      _planSelectedCategoryIds = [widget.preselectedCategoryId!];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFormState() {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    _tagsController.clear();
    _amountString = '';
    _currentStep = 1;
    _isRecurring = false;
    _isGoalContribution = false;
    _selectedCategoryId = null;
    _selectedSubCategoryName = null;
    _selectedSubCategoryIcon = null;
    _planSelectedCategoryIds = [];
    _planStartDate = DateTime.now();
    _planEndDate = DateTime.now().add(const Duration(days: 30));
    _plannedEntries.clear();
    _showAddTransactionForm = false;
    _miniAmountController.clear();
    _miniDescriptionController.clear();
    _miniSelectedCategoryId = null;
    _miniSelectedSubCategoryName = null;
    _miniSelectedSubCategoryIcon = null;
  }

  Future<void> _saveExpense() async {
    debugPrint('[DEBUG] _saveExpense entered. mode: $_mode');
    if (_isSaving) {
      debugPrint('[DEBUG] Save already in progress, ignoring double tap.');
      return;
    }

    if (_mode == TransactionMode.plan) {
      if (!_formKey.currentState!.validate()) {
        debugPrint('[DEBUG] Plan form validation failed');
        return;
      }
    } else {
      if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
        if (_selectedCategoryId == null) {
          debugPrint('[DEBUG] Regular form validation failed: category is null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category')),
          );
        } else {
          debugPrint('[DEBUG] Regular form validation failed');
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_mode == TransactionMode.plan) {
        final planId = const Uuid().v4();
        final derivedCategoryIds = _plannedEntries.map((e) => e.categoryId).toSet().toList();

        final plan = Plan(
          id: planId,
          title: _titleController.text.trim(),
          totalBudget: double.parse(_amountController.text.trim()),
          startDate: _planStartDate,
          endDate: _planEndDate,
          categoryIds: derivedCategoryIds,
          note: '',
          createdAt: DateTime.now(),
        );

        final expenses = _plannedEntries.map((entry) {
          return Expense(
            id: entry.id,
            title: entry.title,
            amount: entry.amount,
            categoryId: entry.categoryId,
            date: _planStartDate,
            note: '',
            type: CategoryType.expense,
            subCategory: entry.subCategory,
            subCategoryIcon: entry.subCategoryIcon,
            planId: planId,
          );
        }).toList();

        final planProvider = context.read<PlanProvider>();
        debugPrint('[DEBUG] Saving plan and ${expenses.length} expenses to Firestore starting...');
        await planProvider.addPlanWithExpenses(plan, expenses);
        debugPrint('[DEBUG] Saving plan and expenses to Firestore completed');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Custom Goal saved'),
            backgroundColor: AppTheme.emeraldGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final expense = Expense(
          id: widget.expenseToEdit?.id ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text,
          type: _mode == TransactionMode.income ? CategoryType.income : CategoryType.expense,
          subCategory: _selectedSubCategoryName,
          subCategoryIcon: _selectedSubCategoryIcon,
          planId: _selectedPlanId,
        );

        final provider = context.read<ExpenseProvider>();
        
        if (widget.expenseToEdit != null) {
          debugPrint('[DEBUG] Updating expense starting...');
          await provider.updateExpense(expense);
          debugPrint('[DEBUG] Updating expense completed');
          messenger.showSnackBar(
            SnackBar(
              content: Text('${_mode == TransactionMode.expense ? 'Expense' : 'Income'} updated'),
              backgroundColor: AppTheme.emeraldGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('[DEBUG] Adding expense starting...');
          await provider.addExpense(expense);
          debugPrint('[DEBUG] Adding expense completed');
          messenger.showSnackBar(
            SnackBar(
              content: Text('${_mode == TransactionMode.expense ? 'Expense' : 'Income'} saved'),
              backgroundColor: AppTheme.emeraldGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] ERROR caught in _saveExpense: $e');
      debugPrint('[DEBUG] STACKTRACE: $stackTrace');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: AppTheme.expenseColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      debugPrint('[DEBUG] Finally block reached in _saveExpense. mounted = $mounted, context.mounted = ${context.mounted}');
      if (context.mounted) {
        debugPrint('[DEBUG] LITERALLY BEFORE Navigator.pop(context) call');
        Navigator.pop(context);
        debugPrint('[DEBUG] LITERALLY AFTER Navigator.pop(context) call');
      } else {
        debugPrint('[DEBUG] Context not mounted in finally block, Navigator.pop(context) skipped');
      }
      _clearFormState();
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showCreateCustomCategoryDialog(BuildContext context, CategoryType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreateCategorySheet(
          categoryProvider: context.read<CategoryProvider>(),
          type: type,
          onSave: (newCategoryId) {
            setState(() {
              _selectedCategoryId = newCategoryId;
              _selectedSubCategoryName = null;
              _selectedSubCategoryIcon = null;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final isIncomeMode = _mode == TransactionMode.income;
    final currentCategoryType = isIncomeMode ? CategoryType.income : CategoryType.expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle: Expense / Income / Plan
              SegmentedButton<TransactionMode>(
                segments: const [
                  ButtonSegment(value: TransactionMode.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: TransactionMode.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                  ButtonSegment(value: TransactionMode.plan, label: Text('Goal'), icon: Icon(Icons.track_changes_rounded)),
                ],
                selected: {_mode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                    _clearFormState();
                  });
                },
              ),
              const SizedBox(height: 24),

              if (_mode == TransactionMode.plan) ...[
                // Plan Mode Form
                _buildSectionLabel('Goal Title'),
                _buildInputCard(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Summer Vacation / Wedding',
                      prefixIcon: Icon(Icons.title),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Total Budget'),
                _buildInputCard(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      prefixText: '${context.watch<SettingsProvider>().currentSymbol} ',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      setState(() {});
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Start Date'),
                          _buildInputCard(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _planStartDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _planStartDate = picked;
                                    if (_planEndDate.isBefore(_planStartDate)) {
                                      _planEndDate = _planStartDate.add(const Duration(days: 30));
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_planStartDate.day}/${_planStartDate.month}/${_planStartDate.year}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('End Date'),
                          _buildInputCard(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _planEndDate,
                                  firstDate: _planStartDate,
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _planEndDate = picked;
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_planEndDate.day}/${_planEndDate.month}/${_planEndDate.year}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXPENSES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Used: ${formatCurrency(_plannedEntries.fold<double>(0.0, (sum, e) => sum + e.amount))} / Budget: ${formatCurrency(double.tryParse(_amountController.text) ?? 0.0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _plannedEntries.fold<double>(0.0, (sum, e) => sum + e.amount) > (double.tryParse(_amountController.text) ?? 0.0)
                            ? AppTheme.expenseColor
                            : AppTheme.emeraldGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddTransactionForm = !_showAddTransactionForm;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
                      foregroundColor: AppTheme.emeraldGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_showAddTransactionForm ? Icons.close : Icons.add, size: 20),
                    label: Text(
                      _showAddTransactionForm ? 'Cancel Add' : 'Add Transaction',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                _buildMiniTransactionForm(context, categories),

                if (_plannedEntries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _plannedEntries.length,
                    itemBuilder: (context, idx) {
                      final entry = _plannedEntries[idx];
                      final category = categories.firstWhere((c) => c.id == entry.categoryId, orElse: () => categories.first);
                      final currencySymbol = context.watch<SettingsProvider>().currentSymbol;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.white.withOpacity(0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(category.icon, color: AppTheme.expenseColor),
                          title: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: entry.subCategory != null
                              ? Row(
                                  children: [
                                    Icon(
                                      entry.subCategoryIcon != null ? IconUtils.getIcon(entry.subCategoryIcon) : Icons.label_outline,
                                      size: 12,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(entry.subCategory!, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                  ],
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCurrency(entry.amount),
                                style: const TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white30),
                                onPressed: () {
                                  setState(() {
                                    _plannedEntries.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveExpense,
                  child: const Text(
                    'Save Goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                if (_currentStep == 1)
                  _buildStep1(categories)
                else
                  _buildStep2(categories)
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildStep1(List<Category> categories) {
    final isIncomeMode = _mode == TransactionMode.income;
    final currentCategoryType = isIncomeMode ? CategoryType.income : CategoryType.expense;
    
    final filteredCategories = categories
        .where((c) => c.type == currentCategoryType && (currentCategoryType != CategoryType.income || c.id != 'other'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final displayColor = isIncomeMode ? AppTheme.incomeColor : AppTheme.expenseColor;
    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TransactionMode>(
          segments: const [
            ButtonSegment(value: TransactionMode.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
            ButtonSegment(value: TransactionMode.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
            ButtonSegment(value: TransactionMode.plan, label: Text('Goal'), icon: Icon(Icons.track_changes_rounded)),
          ],
          selected: {_mode},
          onSelectionChanged: (newSelection) {
            setState(() {
              _mode = newSelection.first;
              _clearFormState();
              _mode = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 32),

        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currencySymbol ${_amountString.isEmpty ? "0.00" : _amountString}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        _buildNumpad(),
        const SizedBox(height: 32),

        _buildSectionLabel('Category'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filteredCategories.map((category) {
              final isSelected = _selectedCategoryId == category.id;
              final catColor = AppTheme.getCategoryColor(category.id, category.name);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                      _selectedSubCategoryName = null;
                      _selectedSubCategoryIcon = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor.withOpacity(0.2) : AppTheme.secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? catColor : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(category.icon, size: 16, color: isSelected ? catColor : Colors.white60),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: (_amountString.isNotEmpty && double.tryParse(_amountString) != null && double.parse(_amountString) > 0 && _selectedCategoryId != null)
              ? () {
                  setState(() {
                    _currentStep = 2;
                  });
                }
              : null,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        _buildNumpadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildNumpadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildNumpadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildNumpadRow(['.', '0', 'backspace']),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        final isBackspace = key == 'backspace';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: InkWell(
                onTap: () => _handleNumpadTap(key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  alignment: Alignment.center,
                  child: isBackspace
                      ? const Icon(Icons.backspace_outlined, color: Colors.white70)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleNumpadTap(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amountString.isNotEmpty) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        }
      } else if (key == '.') {
        if (!_amountString.contains('.')) {
          if (_amountString.isEmpty) {
            _amountString = '0.';
          } else {
            _amountString += '.';
          }
        }
      } else {
        if (_amountString.length >= 10) return;
        if (_amountString.contains('.')) {
          final dotIndex = _amountString.indexOf('.');
          if (_amountString.substring(dotIndex + 1).length >= 2) {
            return;
          }
        }
        if (_amountString == '0') {
          _amountString = key;
        } else {
          _amountString += key;
        }
      }
      _amountController.text = _amountString;
    });
  }

  Widget _buildStep2(List<Category> categories) {
    final selectedCategory = categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first);
    final catColor = AppTheme.getCategoryColor(selectedCategory.id, selectedCategory.name);
    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;
    final planProvider = context.watch<PlanProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _currentStep = 1;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(selectedCategory.icon, color: catColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCategory.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to edit amount or category',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol $_amountString',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _mode == TransactionMode.income ? AppTheme.incomeColor : AppTheme.expenseColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionLabel('Title'),
        _buildInputCard(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Enter title (e.g. Lunch, Taxi)',
              prefixIcon: Icon(Icons.title_rounded),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
          ),
        ),
        const SizedBox(height: 20),

        if (_mode == TransactionMode.expense && _selectedCategoryId != null) ...[
          _buildSectionLabel('Sub-category'),
          _buildInputCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildSubCategorySection(context, categories),
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionLabel('Date'),
        _buildInputCard(
          child: InkWell(
            onTap: () => _selectDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_outlined, size: 20, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Note'),
        _buildInputCard(
          child: TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Additional notes...',
              prefixIcon: Icon(Icons.notes_rounded),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionLabel('Tags'),
        _buildInputCard(
          child: TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              hintText: 'e.g. food, holiday, personal',
              prefixIcon: Icon(Icons.tag_rounded),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Card(
          margin: EdgeInsets.zero,
          color: AppTheme.secondaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Recurring Transaction'),
                subtitle: const Text('Automatically repeat this transaction'),
                value: _isRecurring,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val;
                  });
                },
                activeColor: AppTheme.emeraldGreen,
              ),
              if (_mode == TransactionMode.expense && planProvider.plans.isNotEmpty) ...[
                const Divider(height: 1, color: Colors.white10),
                SwitchListTile(
                  title: const Text('Goal Contribution'),
                  subtitle: const Text('Link this expense to a savings goal'),
                  value: _isGoalContribution,
                  onChanged: (val) {
                    setState(() {
                      _isGoalContribution = val;
                      if (!val) {
                        _selectedPlanId = null;
                      } else {
                        _selectedPlanId = planProvider.plans.first.id;
                      }
                    });
                  },
                  activeColor: AppTheme.emeraldGreen,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_isGoalContribution && _mode == TransactionMode.expense && planProvider.plans.isNotEmpty) ...[
          _buildSectionLabel('Select Goal'),
          _buildInputCard(
            child: DropdownButtonFormField<String>(
              value: _selectedPlanId,
              decoration: const InputDecoration(
                hintText: 'Select Goal',
                prefixIcon: Icon(Icons.track_changes_rounded),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: planProvider.plans.map((plan) => DropdownMenuItem<String>(
                value: plan.id,
                child: Text(plan.title),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPlanId = val;
                });
              },
            ),
          ),
          const SizedBox(height: 32),
        ] else ...[
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveExpense,
                child: Text(
                  _mode == TransactionMode.expense ? 'Save Expense' : 'Save Income',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  final List<IconData> _curatedIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.local_taxi,
    Icons.local_parking,
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.checkroom,
    Icons.devices,
    Icons.receipt,
    Icons.bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.phone_android,
    Icons.medical_services,
    Icons.local_pharmacy,
    Icons.medical_information,
    Icons.home,
    Icons.apartment,
    Icons.build,
    Icons.chair,
    Icons.movie,
    Icons.school,
    Icons.card_giftcard,
    Icons.add_circle,
  ];

  bool _isDefaultSubCategory(Category category, String subName) {
    final defaultCat = Category.defaultCategories.firstWhere(
      (c) => c.id == category.id,
      orElse: () => const Category(id: '', name: '', type: CategoryType.expense, icon: Icons.category, subCategories: []),
    );
    return defaultCat.subCategories.any((s) => s.name.toLowerCase() == subName.toLowerCase());
  }

  Future<void> _deleteSubCategory(BuildContext context, Category category, SubCategory sub, {bool isMini = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-category'),
        content: Text('Are you sure you want to delete "${sub.name}"? This won\'t affect past transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final updatedSubs = List<SubCategory>.from(category.subCategories)
        ..removeWhere((s) => s.name == sub.name);
      final updatedCategory = Category(
        id: category.id,
        name: category.name,
        type: category.type,
        icon: category.icon,
        subCategories: updatedSubs,
      );
      
      await context.read<CategoryProvider>().update(updatedCategory);
      final currentSelectedName = isMini ? _miniSelectedSubCategoryName : _selectedSubCategoryName;
      if (currentSelectedName == sub.name) {
        setState(() {
          if (isMini) {
            _miniSelectedSubCategoryName = null;
            _miniSelectedSubCategoryIcon = null;
          } else {
            _selectedSubCategoryName = null;
            _selectedSubCategoryIcon = null;
          }
        });
      }
    }
  }

  Widget _buildSubCategorySection(BuildContext context, List<Category> categories, {bool isMini = false}) {
    final targetCategoryId = isMini ? _miniSelectedCategoryId : _selectedCategoryId;
    final targetSelectedSubName = isMini ? _miniSelectedSubCategoryName : _selectedSubCategoryName;

    if (targetCategoryId == null) {
      return const Text(
        'Please select a category first',
        style: TextStyle(color: Colors.white54, fontSize: 14),
      );
    }

    final category = categories.firstWhere((c) => c.id == targetCategoryId, orElse: () => categories.first);
    if (category.subCategories.isEmpty) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 16, color: AppTheme.emeraldGreen),
            label: const Text('Add Custom', style: TextStyle(color: AppTheme.emeraldGreen)),
            onPressed: () => _showAddCustomSubCategoryDialog(context, category, isMini: isMini),
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ],
      );
    }

    final List<Widget> chips = [];
    for (var sub in category.subCategories) {
      final isSelected = targetSelectedSubName == sub.name;
      final isDefault = _isDefaultSubCategory(category, sub.name);
      chips.add(
        InputChip(
          avatar: Icon(sub.icon, size: 16, color: isSelected ? Colors.white : Colors.white54),
          label: Text(sub.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (isMini) {
                  _miniSelectedSubCategoryName = sub.name;
                  _miniSelectedSubCategoryIcon = IconUtils.getIconName(sub.icon);
                } else {
                  _selectedSubCategoryName = sub.name;
                  _selectedSubCategoryIcon = IconUtils.getIconName(sub.icon);
                }
              } else {
                if (isMini) {
                  _miniSelectedSubCategoryName = null;
                  _miniSelectedSubCategoryIcon = null;
                } else {
                  _selectedSubCategoryName = null;
                  _selectedSubCategoryIcon = null;
                }
              }
            });
          },
          onDeleted: isDefault
              ? null
              : () => _deleteSubCategory(context, category, sub, isMini: isMini),
          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white70),
          selectedColor: AppTheme.emeraldGreen,
          backgroundColor: Colors.white.withOpacity(0.05),
          showCheckmark: false,
        ),
      );
    }

    chips.add(
      ActionChip(
        avatar: const Icon(Icons.add, size: 16, color: AppTheme.emeraldGreen),
        label: const Text('Add Custom', style: TextStyle(color: AppTheme.emeraldGreen)),
        onPressed: () => _showAddCustomSubCategoryDialog(context, category, isMini: isMini),
        backgroundColor: Colors.white.withOpacity(0.05),
      ),
    );

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: chips,
    );
  }

  void _showAddCustomSubCategoryDialog(BuildContext context, Category category, {bool isMini = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddSubCategorySheet(
          category: category,
          curatedIcons: _curatedIcons,
          onSave: (name, icon) async {
            final newSub = SubCategory(name: name, icon: icon);
            final updatedSubs = List<SubCategory>.from(category.subCategories)..add(newSub);
            final updatedCategory = Category(
              id: category.id,
              name: category.name,
              type: category.type,
              icon: category.icon,
              subCategories: updatedSubs,
            );
            
            await context.read<CategoryProvider>().update(updatedCategory);
            
            setState(() {
              if (isMini) {
                _miniSelectedSubCategoryName = name;
                _miniSelectedSubCategoryIcon = IconUtils.getIconName(icon);
              } else {
                _selectedSubCategoryName = name;
                _selectedSubCategoryIcon = IconUtils.getIconName(icon);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildMiniTransactionForm(BuildContext context, List<Category> categories) {
    if (!_showAddTransactionForm) return const SizedBox.shrink();

    final currentCategoryType = CategoryType.expense;

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Entry Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          _buildSectionLabel('Amount'),
          _buildInputCard(
            child: TextFormField(
              controller: _miniAmountController,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionLabel('Category'),
          _buildInputCard(
            child: DropdownButtonFormField<String>(
              value: _miniSelectedCategoryId,
              decoration: const InputDecoration(
                hintText: 'Select Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: () {
                final Map<String, Category> unique = {};
                for (var c in categories.where((c) => c.type == currentCategoryType)) {
                  unique[c.id] = c;
                }
                final sorted = unique.values.toList()..sort((a, b) => a.name.compareTo(b.name));
                return sorted.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        category.icon,
                        size: 20,
                        color: AppTheme.expenseColor,
                      ),
                      const SizedBox(width: 12),
                      Text(category.name),
                    ],
                  ),
                )).toList();
              }(),
              onChanged: (value) {
                setState(() {
                  _miniSelectedCategoryId = value;
                  _miniSelectedSubCategoryName = null;
                  _miniSelectedSubCategoryIcon = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          if (_miniSelectedCategoryId != null) ...[
            _buildSectionLabel('Sub-category'),
            _buildInputCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildSubCategorySection(context, categories, isMini: true),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildSectionLabel('Description'),
          _buildInputCard(
            child: TextFormField(
              controller: _miniDescriptionController,
              decoration: const InputDecoration(
                hintText: 'Short description/title...',
                prefixIcon: Icon(Icons.notes),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final amountText = _miniAmountController.text.trim();
              final categoryId = _miniSelectedCategoryId;
              final descText = _miniDescriptionController.text.trim();

              if (amountText.isEmpty || double.tryParse(amountText) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              if (categoryId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a category')),
                );
                return;
              }

              setState(() {
                _plannedEntries.add(
                  PlannedTransactionEntry(
                    id: const Uuid().v4(),
                    title: descText.isEmpty ? 'Planned Expense' : descText,
                    amount: double.parse(amountText),
                    categoryId: categoryId,
                    subCategory: _miniSelectedSubCategoryName,
                    subCategoryIcon: _miniSelectedSubCategoryIcon,
                  ),
                );

                _miniAmountController.clear();
                _miniDescriptionController.clear();
                _miniSelectedCategoryId = null;
                _miniSelectedSubCategoryName = null;
                _miniSelectedSubCategoryIcon = null;
                _showAddTransactionForm = false;
              });
            },
            child: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AddSubCategorySheet extends StatefulWidget {
  final Category category;
  final List<IconData> curatedIcons;
  final Function(String name, IconData icon) onSave;

  const _AddSubCategorySheet({
    required this.category,
    required this.curatedIcons,
    required this.onSave,
  });

  @override
  State<_AddSubCategorySheet> createState() => _AddSubCategorySheetState();
}

class _AddSubCategorySheetState extends State<_AddSubCategorySheet> {
  final _nameController = TextEditingController();
  IconData? _selectedIcon;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Sub-category under ${widget.category.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Sub-category name',
                prefixIcon: Icon(Icons.label_outline),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose Icon',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.curatedIcons.length,
              itemBuilder: (context, index) {
                final icon = widget.curatedIcons[index];
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.emeraldGreen : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.emeraldGreen : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (_nameController.text.trim().isEmpty || _selectedIcon == null || _isSaving)
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    await widget.onSave(_nameController.text.trim(), _selectedIcon!);
                    Navigator.pop(context);
                  },
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Sub-category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
