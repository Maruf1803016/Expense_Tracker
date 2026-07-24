import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';

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
  late TextEditingController _miniAmountController;
  late TextEditingController _miniDescriptionController;
  String? _miniSelectedCategoryId;
  String? _miniSelectedSubCategoryName;
  String? _miniSelectedSubCategoryIcon;

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
    _miniAmountController = TextEditingController();
    _miniDescriptionController = TextEditingController();
    _selectedCategoryId = widget.preselectedCategoryId ?? widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    
    if (widget.expenseToEdit != null) {
      _mode = widget.expenseToEdit!.type == CategoryType.income
          ? TransactionMode.income
          : TransactionMode.expense;
    } else {
      _mode = TransactionMode.expense;
    }
    
    _selectedSubCategoryName = widget.expenseToEdit?.subCategory;
    _selectedSubCategoryIcon = widget.expenseToEdit?.subCategoryIcon;
    _selectedPlanId = widget.preselectedPlanId ?? widget.expenseToEdit?.planId;
    
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
            content: Text('Custom Plan saved'),
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
      _clearFormState();
      debugPrint('[DEBUG] Finally block reached in _saveExpense. mounted = $mounted, context.mounted = ${context.mounted}');
      if (context.mounted) {
        debugPrint('[DEBUG] Calling Navigator.pop(context) in finally block');
        Navigator.pop(context);
        debugPrint('[DEBUG] Navigator.pop(context) completed in finally block');
      } else {
        debugPrint('[DEBUG] Context not mounted in finally block, Navigator.pop(context) skipped');
      }
    }
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
                  ButtonSegment(value: TransactionMode.plan, label: Text('Plan'), icon: Icon(Icons.assignment_outlined)),
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
                _buildSectionLabel('Plan Title'),
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
                      'Used: ${context.watch<SettingsProvider>().currentSymbol} ${_plannedEntries.fold<double>(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)} / Budget: ${context.watch<SettingsProvider>().currentSymbol} ${(double.tryParse(_amountController.text) ?? 0.0).toStringAsFixed(2)}',
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

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAddTransactionForm = !_showAddTransactionForm;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showAddTransactionForm ? 'Cancel Add' : 'Add Transaction',
                      style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold),
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
                                '$currencySymbol ${entry.amount.toStringAsFixed(2)}',
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
                    'Save Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                // Regular Expense/Income Form
                _buildSectionLabel('Title'),
                _buildInputCard(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter title',
                      prefixIcon: Icon(Icons.title_rounded),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Amount'),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('Category'),
                _buildInputCard(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
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
                              color: isIncomeMode ? AppTheme.incomeColor : AppTheme.expenseColor,
                            ),
                            const SizedBox(width: 12),
                            Text(category.name),
                          ],
                        ),
                      )).toList();
                    }(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedSubCategoryName = null;
                        _selectedSubCategoryIcon = null;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
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
                const SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveExpense,
                  child: Text(
                    _mode == TransactionMode.expense ? 'Save Expense' : 'Save Income',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
