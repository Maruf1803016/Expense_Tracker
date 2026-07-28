import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';
import 'package:expense_tracker/features/recurring_income/presentation/providers/recurring_income_provider.dart';

enum TransactionMode {
  expense,
  income,
  plan,
}

class AddExpensePage extends StatefulWidget {
  final Expense? expenseToEdit;
  final String? preselectedPlanId;
  final String? preselectedCategoryId;
  final bool preselectedPlanMode;

  const AddExpensePage({
    super.key,
    this.expenseToEdit,
    this.preselectedPlanId,
    this.preselectedCategoryId,
    this.preselectedPlanMode = false,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _subCategoryController;
  
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  TransactionMode _mode = TransactionMode.expense;
  String? _selectedPlanId;
  String? _selectedAccountId;

  // Plan Mode specific fields
  DateTime _planStartDate = DateTime.now();
  DateTime _planEndDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  DateTime _recurringNextDueDate = DateTime.now().add(const Duration(days: 30));

  void _updateDefaultNextDueDate() {
    final now = DateTime.now();
    switch (_recurringFrequency) {
      case 'weekly':
        _recurringNextDueDate = now.add(const Duration(days: 7));
        break;
      case 'biweekly':
        _recurringNextDueDate = now.add(const Duration(days: 14));
        break;
      case 'monthly':
        int nextYear = now.year;
        int nextMonth = now.month + 1;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        }
        int nextDay = now.day;
        int daysInNextMonth = _getDaysInMonth(nextYear, nextMonth);
        if (nextDay > daysInNextMonth) {
          nextDay = daysInNextMonth;
        }
        _recurringNextDueDate = DateTime(nextYear, nextMonth, nextDay, now.hour, now.minute, now.second);
        break;
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      return 31;
    }
    if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    }
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
      return 29;
    }
    return 28;
  }

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
    _subCategoryController = TextEditingController(
      text: widget.expenseToEdit?.subCategory ?? '',
    );
    
    _selectedCategoryId = widget.preselectedCategoryId ?? widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _selectedPlanId = widget.preselectedPlanId ?? widget.expenseToEdit?.planId;
    _selectedAccountId = widget.expenseToEdit?.accountId;

    if (widget.preselectedPlanMode) {
      _mode = TransactionMode.plan;
    } else if (widget.expenseToEdit != null) {
      _mode = widget.expenseToEdit!.type == CategoryType.income
          ? TransactionMode.income
          : TransactionMode.expense;
    } else {
      _mode = TransactionMode.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _subCategoryController.dispose();
    super.dispose();
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

  Future<void> _saveExpense() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mode != TransactionMode.plan && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_mode == TransactionMode.plan) {
        final planId = const Uuid().v4();
        final plan = Plan(
          id: planId,
          title: _titleController.text.trim(),
          totalBudget: double.parse(_amountController.text.trim()),
          startDate: _planStartDate,
          endDate: _planEndDate,
          categoryIds: const ['investment'],
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );

        final planProvider = context.read<PlanProvider>();
        await planProvider.addPlanWithExpenses(plan, []);
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Goal saved successfully'),
            backgroundColor: AppTheme.emerald,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final expense = Expense(
          id: widget.expenseToEdit?.id ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim(),
          accountId: _selectedAccountId!,
          subCategory: _subCategoryController.text.trim().isEmpty
              ? null
              : _subCategoryController.text.trim(),
          type: _mode == TransactionMode.income ? CategoryType.income : CategoryType.expense,
          planId: _selectedPlanId,
        );

        final provider = context.read<ExpenseProvider>();
        if (widget.expenseToEdit != null) {
          await provider.updateExpense(expense);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transaction updated'),
              backgroundColor: AppTheme.emerald,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await provider.addExpense(expense);
          
          if (_mode == TransactionMode.income && _isRecurring) {
            final recurringProvider = context.read<RecurringIncomeProvider>();
            final source = RecurringIncomeSource(
              id: const Uuid().v4(),
              name: expense.title,
              expectedAmount: expense.amount,
              frequency: _recurringFrequency,
              nextDueDate: _recurringNextDueDate,
              status: 'pending',
              categoryId: expense.categoryId,
              accountId: expense.accountId,
              createdAt: DateTime.now(),
            );
            await recurringProvider.addSource(source);
          }

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transaction saved'),
              backgroundColor: AppTheme.emerald,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.brick,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteExpense() async {
    if (widget.expenseToEdit == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ExpenseProvider>();
      final messenger = ScaffoldMessenger.of(context);
      try {
        await provider.deleteExpense(widget.expenseToEdit!.id);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final planProvider = context.watch<PlanProvider>();
    final plans = planProvider.plans.where((p) => !p.isArchived).toList();
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      if (widget.expenseToEdit != null) {
        _selectedAccountId = widget.expenseToEdit!.accountId;
      } else if (accounts.length == 1) {
        _selectedAccountId = accounts.first.id;
      }
    }

    final hasSelected = accounts.any((a) => a.id == _selectedAccountId);
    if (_selectedAccountId != null && !hasSelected && accounts.isNotEmpty) {
      _selectedAccountId = accounts.any((a) => a.isDefault) 
          ? accounts.firstWhere((a) => a.isDefault).id 
          : accounts.first.id;
    }
    
    final isIncomeMode = _mode == TransactionMode.income;
    final currentCategoryType = isIncomeMode ? CategoryType.income : CategoryType.expense;

    final filteredCategories = categories
        .where((c) => c.type == currentCategoryType && (currentCategoryType != CategoryType.income || c.id != 'other'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;
    final displayColor = _mode == TransactionMode.expense 
        ? AppTheme.brick 
        : (_mode == TransactionMode.income ? AppTheme.emerald : AppTheme.gold);

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit != null ? 'Edit Transaction' : (_mode == TransactionMode.plan ? 'New Goal' : 'New Transaction'),
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented toggle
              if (widget.expenseToEdit == null && !widget.preselectedPlanMode)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton('Expense', TransactionMode.expense),
                      _buildToggleButton('Income', TransactionMode.income),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Large Space Grotesk amount display
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currencySymbol,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: displayColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.spaceGrotesk(color: AppTheme.muted.withOpacity(0.3)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_mode == TransactionMode.plan) ...[
                // Plan form
                _buildSectionLabel('Goal Title'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Summer Vacation',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Start Date'),
                _buildDateTile(_planStartDate, (date) {
                  setState(() {
                    _planStartDate = date;
                  });
                }),
                const SizedBox(height: 16),
                _buildSectionLabel('End Date'),
                _buildDateTile(_planEndDate, (date) {
                  setState(() {
                    _planEndDate = date;
                  });
                }),
              ] else ...[
                // Transaction Form (Expense/Income)
                ...[
                  _buildSectionLabel('Category'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, idx) {
                      final category = filteredCategories[idx];
                      final isSelected = _selectedCategoryId == category.id;
                      final catColor = AppTheme.getCategoryColor(category.id, category.name);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? catColor.withOpacity(0.15) : AppTheme.paper2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? catColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(category.icon, color: isSelected ? catColor : AppTheme.muted, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.textDark : AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                _buildSectionLabel('Account'),
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Select Account',
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Row(
                        children: [
                          Icon(acc.icon, color: acc.color, size: 18),
                          const SizedBox(width: 8),
                          Text(acc.name, style: GoogleFonts.inter(color: AppTheme.textDark)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccountId = val;
                    });
                  },
                  validator: (val) => val == null || val.isEmpty ? 'Please select an account' : null,
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Sub-category (Optional)'),
                TextFormField(
                  controller: _subCategoryController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Coffee, Bus fare',
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Title / Merchant'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Starbucks',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Date'),
                _buildDateTile(_selectedDate, (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                }),
                const SizedBox(height: 16),

                _buildSectionLabel('Notes (Optional)'),
                TextFormField(
                  controller: _noteController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                  ),
                ),
                const SizedBox(height: 16),

                if (plans.isNotEmpty) ...[
                  _buildSectionLabel('Link to Goal (Optional)'),
                  DropdownButtonFormField<String>(
                    value: _selectedPlanId,
                    dropdownColor: AppTheme.paperCard,
                    style: GoogleFonts.inter(color: AppTheme.textDark),
                    decoration: const InputDecoration(
                      hintText: 'No goal linked',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No goal linked'),
                      ),
                      ...plans.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(p.title),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPlanId = val;
                      });
                    },
                  ),
                ],
                if (_mode == TransactionMode.income && widget.expenseToEdit == null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    title: Text(
                      'Recurring income',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically track this income frequency',
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12),
                    ),
                    value: _isRecurring,
                    activeColor: AppTheme.emerald,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _isRecurring = val;
                        if (_isRecurring) {
                          _updateDefaultNextDueDate();
                        }
                      });
                    },
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 16),
                    _buildSectionLabel('Frequency'),
                    DropdownButtonFormField<String>(
                      value: _recurringFrequency,
                      dropdownColor: AppTheme.paperCard,
                      style: GoogleFonts.inter(color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Select Frequency',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _recurringFrequency = val;
                            _updateDefaultNextDueDate();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Next Due Date'),
                    _buildDateTile(_recurringNextDueDate, (date) {
                      setState(() {
                        _recurringNextDueDate = date;
                      });
                    }),
                  ],
                ],
              ],
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveExpense,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.expenseToEdit != null ? 'Save Changes' : 'Save Transaction',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),

              if (widget.expenseToEdit != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _deleteExpense,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
                  child: const Text('Delete Transaction'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, TransactionMode mode) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = mode;
            _selectedCategoryId = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? AppTheme.goldSoft : AppTheme.muted,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateTile(DateTime date, Function(DateTime) onDatePicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          onDatePicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.paperCard,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormatter.format(date),
              style: GoogleFonts.inter(color: AppTheme.textDark),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
