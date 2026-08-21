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
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

enum TransactionMode {
  expense,
  income,
  transfer,
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
  late TextEditingController _financedAmountController;
  late TextEditingController _payerPayeeController;
  String? _selectedSubCategoryName;
  String? _selectedSubCategoryIconName;
  
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  TransactionMode _mode = TransactionMode.expense;
  String? _selectedPlanId;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  PaymentStatus _paymentStatus = PaymentStatus.settled;
  String? _selectedPaymentMethod;

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
    _financedAmountController = TextEditingController();
    _payerPayeeController = TextEditingController(
      text: widget.expenseToEdit?.payerPayee ?? '',
    );
    _selectedSubCategoryName = widget.expenseToEdit?.subCategory;
    _selectedSubCategoryIconName = widget.expenseToEdit?.subCategoryIcon;
    
    _selectedCategoryId = widget.preselectedCategoryId ?? widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _selectedPlanId = widget.preselectedPlanId ?? widget.expenseToEdit?.planId;
    _selectedAccountId = widget.expenseToEdit?.accountId;
    _selectedToAccountId = widget.expenseToEdit?.toAccountId;
    _paymentStatus = widget.expenseToEdit?.paymentStatus ?? PaymentStatus.settled;
    _selectedPaymentMethod = widget.expenseToEdit?.paymentMethod;

    if (widget.preselectedPlanMode) {
      _mode = TransactionMode.plan;
    } else if (widget.expenseToEdit != null) {
      if (widget.expenseToEdit!.type == CategoryType.income) {
        _mode = TransactionMode.income;
      } else if (widget.expenseToEdit!.type == CategoryType.transfer) {
        _mode = TransactionMode.transfer;
      } else {
        _mode = TransactionMode.expense;
      }
    } else {
      _mode = TransactionMode.expense;
    }
  }

  bool _accountDefaultApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_accountDefaultApplied) {
      final accounts = context.watch<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        setState(() {
          if (_selectedAccountId == null) {
            _selectedAccountId = widget.expenseToEdit?.accountId ?? (accounts.length == 1 ? accounts.first.id : null);
          }
          final hasSelected = accounts.any((a) => a.id == _selectedAccountId);
          if (_selectedAccountId != null && !hasSelected) {
            _selectedAccountId = accounts.any((a) => a.isDefault) 
                ? accounts.firstWhere((a) => a.isDefault).id 
                : accounts.first.id;
          }
          _accountDefaultApplied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _financedAmountController.dispose();
    _payerPayeeController.dispose();
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
    debugPrint('[AddExpensePage] _saveExpense() called');
    if (_isSaving) {
      debugPrint('[AddExpensePage] _isSaving is true, aborting duplicate save');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AddExpensePage] Form validation failed');
      return;
    }
    debugPrint('[AddExpensePage] Form validation succeeded');

    if (_mode != TransactionMode.plan && _mode != TransactionMode.transfer && _selectedCategoryId == null) {
      debugPrint('[AddExpensePage] Category not selected in standard mode');
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
      debugPrint('[AddExpensePage] Saving with mode: $_mode');
      if (_mode == TransactionMode.plan) {
        final planId = const Uuid().v4();
        final plan = Goal(
          id: planId,
          title: _titleController.text.trim(),
          totalBudget: double.parse(_amountController.text.trim()),
          startDate: _planStartDate,
          endDate: _planEndDate,
          categoryIds: const ['investment'],
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
          financedAmount: double.tryParse(_financedAmountController.text.trim()),
        );

        final planProvider = context.read<GoalProvider>();
        debugPrint('[AddExpensePage] Calling planProvider.addPlanWithExpenses');
        await planProvider.addPlanWithExpenses(plan, []);
        debugPrint('[AddExpensePage] planProvider.addPlanWithExpenses completed successfully');
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Goal saved successfully'),
            backgroundColor: AppTheme.emerald,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (_mode == TransactionMode.transfer) {
        if (_selectedAccountId == null || _selectedToAccountId == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Please select both From and To accounts')),
          );
          setState(() => _isSaving = false);
          return;
        }
        if (_selectedAccountId == _selectedToAccountId) {
          messenger.showSnackBar(
            const SnackBar(content: Text('From and To accounts must be different')),
          );
          setState(() => _isSaving = false);
          return;
        }

        final expense = Expense(
          id: widget.expenseToEdit?.id ?? const Uuid().v4(),
          title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Account Transfer',
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId ?? 'transfer',
          date: _selectedDate,
          note: _noteController.text.trim(),
          accountId: _selectedAccountId!,
          toAccountId: _selectedToAccountId,
          type: CategoryType.transfer,
          paymentStatus: _paymentStatus,
          paymentMethod: _selectedPaymentMethod,
          payerPayee: _payerPayeeController.text.trim().isNotEmpty ? _payerPayeeController.text.trim() : null,
        );

        final provider = context.read<ExpenseProvider>();
        if (widget.expenseToEdit != null) {
          await provider.updateExpense(expense);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transfer updated'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        } else {
          await provider.addExpense(expense);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transfer completed'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        }
      } else {
        final expense = Expense(
          id: widget.expenseToEdit?.id ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim(),
          accountId: _selectedAccountId!,
          subCategory: _mode == TransactionMode.income ? null : _selectedSubCategoryName,
          subCategoryIcon: _mode == TransactionMode.income ? null : _selectedSubCategoryIconName,
          type: _mode == TransactionMode.income ? CategoryType.income : CategoryType.expense,
          planId: _selectedPlanId,
          paymentStatus: _paymentStatus,
          paymentMethod: _selectedPaymentMethod,
          payerPayee: _payerPayeeController.text.trim().isNotEmpty ? _payerPayeeController.text.trim() : null,
        );

        final provider = context.read<ExpenseProvider>();
        if (widget.expenseToEdit != null) {
          debugPrint('[AddExpensePage] Calling provider.updateExpense');
          await provider.updateExpense(expense);
          debugPrint('[AddExpensePage] provider.updateExpense completed successfully');
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transaction updated'),
              backgroundColor: AppTheme.emerald,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('[AddExpensePage] Calling provider.addExpense');
          await provider.addExpense(expense);
          debugPrint('[AddExpensePage] provider.addExpense completed successfully');
          
          if ((_mode == TransactionMode.income || _mode == TransactionMode.expense) && _isRecurring) {
            final recurringProvider = context.read<RecurringTransactionProvider>();
            final source = RecurringTransactionSource(
              id: const Uuid().v4(),
              name: expense.title,
              expectedAmount: expense.amount,
              frequency: _recurringFrequency,
              nextDueDate: _recurringNextDueDate,
              status: 'pending',
              type: _mode == TransactionMode.income ? 'income' : 'expense',
              categoryId: expense.categoryId,
              accountId: expense.accountId,
              createdAt: DateTime.now(),
            );
            debugPrint('[AddExpensePage] Calling recurringProvider.addSource');
            await recurringProvider.addSource(source);
            debugPrint('[AddExpensePage] recurringProvider.addSource completed successfully');
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
      
      debugPrint('[AddExpensePage] Reached end of try block, calling Navigator.pop');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint('[AddExpensePage] Save failed with exception: $e');
      debugPrint('[AddExpensePage] Stacktrace: $stack');
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
    final goalProvider = context.watch<GoalProvider>();
    final goals = goalProvider.plans.where((p) => !p.isArchived).toList();
    final tripPlanProvider = context.watch<TripPlanProvider>();
    final tripPlans = tripPlanProvider.tripPlans;
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    final isIncomeMode = _mode == TransactionMode.income;
    final currentCategoryType = isIncomeMode ? CategoryType.income : CategoryType.expense;

    final filteredCategories = categories
        .where((c) => c.type == currentCategoryType && (currentCategoryType != CategoryType.income || c.id != 'other'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    Category? selectedCategory;
    try {
      if (_selectedCategoryId != null && categories.isNotEmpty) {
        selectedCategory = categories.firstWhere((c) => c.id == _selectedCategoryId);
      }
    } catch (_) {}

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
                      _buildToggleButton('Transfer', TransactionMode.transfer),
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
                _buildSectionLabel('Financed Amount (Optional)'),
                TextFormField(
                  controller: _financedAmountController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5000.00',
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('End Date'),
                _buildDateTile(_planEndDate, (date) {
                  setState(() {
                    _planEndDate = date;
                  });
                }),
              ] else if (_mode == TransactionMode.transfer) ...[
                // Transfer form
                _buildSectionLabel('From Account'),
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Select source account',
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Row(
                        children: [
                          IconUtils.buildIcon(
                            IconUtils.getIconName(acc.icon),
                            color: acc.color,
                            size: 18,
                          ),
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
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('To Account'),
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedToAccountId) ? _selectedToAccountId : null,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Select destination account',
                  ),
                  items: accounts.where((a) => a.id != _selectedAccountId).map((acc) {
                    return DropdownMenuItem<String>(
                      value: acc.id,
                      child: Row(
                        children: [
                          IconUtils.buildIcon(
                            IconUtils.getIconName(acc.icon),
                            color: acc.color,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(acc.name, style: GoogleFonts.inter(color: AppTheme.textDark)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedToAccountId = val;
                    });
                  },
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Description (Optional)'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Transfer to Savings',
                  ),
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
              ] else ...[
                // Transaction Form (Expense/Income)
                ...[
                  _buildCompactCategorySection(context, filteredCategories, currentCategoryType, selectedCategory),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSectionLabel('Account'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () async {
                          final accountProvider = context.read<AccountProvider>();
                          Account? foundCash;
                          for (final a in accountProvider.accounts) {
                            if (a.name.toLowerCase() == 'cash') {
                              foundCash = a;
                              break;
                            }
                          }
                          if (foundCash != null) {
                            setState(() {
                              _selectedAccountId = foundCash!.id;
                            });
                          } else {
                            final cashIcon = IconUtils.getIcon('cash');
                            final newCashAccount = Account(
                              id: const Uuid().v4(),
                              name: 'Cash',
                              icon: cashIcon,
                              color: AppTheme.categoryPalette[5],
                              initialBalance: 0.0,
                              isDefault: false,
                              createdAt: DateTime.now(),
                            );
                            await accountProvider.add(newCashAccount);
                            setState(() {
                              _selectedAccountId = newCashAccount.id;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            border: Border.all(color: AppTheme.line),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconUtils.getIcon('cash'), size: 12, color: AppTheme.muted),
                              const SizedBox(width: 4),
                              Text(
                                'Cash',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
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
                          IconUtils.buildIcon(
                            IconUtils.getIconName(acc.icon),
                            color: acc.color,
                            size: 18,
                          ),
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

                _buildSectionLabel('Payment Status'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentStatus = PaymentStatus.settled),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _paymentStatus == PaymentStatus.settled ? AppTheme.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Settled',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _paymentStatus == PaymentStatus.settled ? AppTheme.goldSoft : AppTheme.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentStatus = PaymentStatus.pending),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _paymentStatus == PaymentStatus.pending ? AppTheme.gold : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pending',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _paymentStatus == PaymentStatus.pending ? Colors.white : AppTheme.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Payment Method (Optional)'),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Select payment method',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None (Default)')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'bKash', child: Text('bKash')),
                    DropdownMenuItem(value: 'Nagad', child: Text('Nagad')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedPaymentMethod = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                _buildSectionLabel(_mode == TransactionMode.income ? 'Payer / Source (Optional)' : 'Payee / Recipient (Optional)'),
                TextFormField(
                  controller: _payerPayeeController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: _mode == TransactionMode.income ? 'e.g. Client or Employer' : 'e.g. Restaurant or Merchant',
                  ),
                ),
                const SizedBox(height: 16),

                if (tripPlans.isNotEmpty) ...[
                  _buildSectionLabel('Link to Trip Plan (Optional)'),
                  DropdownButtonFormField<String>(
                    value: (tripPlans.any((p) => p.id == _selectedPlanId) || _selectedPlanId == null) ? _selectedPlanId : null,
                    dropdownColor: AppTheme.paperCard,
                    style: GoogleFonts.inter(color: AppTheme.textDark),
                    decoration: const InputDecoration(
                      hintText: 'No trip plan linked',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No trip plan linked'),
                      ),
                      ...tripPlans.map((p) {
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
                  const SizedBox(height: 16),
                ],

                if (goals.isNotEmpty) ...[
                  _buildSectionLabel('Link to Goal (Optional)'),
                  DropdownButtonFormField<String>(
                    value: (goals.any((p) => p.id == _selectedPlanId) || _selectedPlanId == null) ? _selectedPlanId : null,
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
                      ...goals.map((p) {
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
                  const SizedBox(height: 16),
                ],
                if ((_mode == TransactionMode.income || _mode == TransactionMode.expense) && widget.expenseToEdit == null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    title: Text(
                      'Make this recurring',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically track this transaction schedule',
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12),
                    ),
                    value: _isRecurring,
                    activeColor: _mode == TransactionMode.income ? AppTheme.emerald : AppTheme.gold,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.expenseToEdit != null
                            ? 'Save Changes'
                            : (_mode == TransactionMode.plan
                                ? 'Save Goal'
                                : (_mode == TransactionMode.income
                                    ? 'Save Income'
                                    : (_mode == TransactionMode.transfer
                                        ? 'Save Transfer'
                                        : 'Save Expense'))),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
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
            _selectedSubCategoryName = null;
            _selectedSubCategoryIconName = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? AppTheme.goldSoft : AppTheme.muted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppTheme.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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

  Widget _buildCompactCategorySection(BuildContext context, List<Category> filteredCategories, CategoryType currentCategoryType, Category? selectedCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Category'),
            InkWell(
              onTap: () => _showAllCategoriesSheet(context, filteredCategories, currentCategoryType),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      'All Categories (${filteredCategories.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.gold),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Active Category Card or Selector Row
        if (selectedCategory != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.getCategoryColor(selectedCategory.id, selectedCategory.name).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      IconUtils.getIcon(IconUtils.getIconName(selectedCategory.icon), categoryName: selectedCategory.name),
                      size: 14,
                      color: AppTheme.getCategoryColor(selectedCategory.id, selectedCategory.name),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCategory.name,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      if (_selectedSubCategoryName != null)
                        Text(
                          'Subcategory: $_selectedSubCategoryName',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showAllCategoriesSheet(context, filteredCategories, currentCategoryType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.paper2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Row(
                      children: [
                        Text('Change', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.ink),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Quick Picks Horizontal Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...filteredCategories.take(6).map((category) {
                final isSelected = _selectedCategoryId == category.id;
                final catColor = AppTheme.getCategoryColor(category.id, category.name);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                      _selectedSubCategoryName = null;
                      _selectedSubCategoryIconName = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.ink : AppTheme.paper2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.ink : AppTheme.line,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconUtils.getIcon(IconUtils.getIconName(category.icon), categoryName: category.name),
                          color: isSelected ? AppTheme.goldSoft : catColor,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _showAllCategoriesSheet(context, filteredCategories, currentCategoryType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.more_horiz_rounded, size: 14, color: AppTheme.muted),
                      const SizedBox(width: 3),
                      Text('More', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_mode == TransactionMode.expense && selectedCategory != null)
          _buildSubCategorySection(context, selectedCategory),
      ],
    );
  }

  void _showAllCategoriesSheet(BuildContext context, List<Category> categories, CategoryType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select ${type == CategoryType.expense ? 'Expense' : 'Income'} Category',
                    style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.muted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.line),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  if (idx == categories.length) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CreateCategorySheet(
                            categoryProvider: context.read<CategoryProvider>(),
                            type: type,
                            onSave: (newCategoryId) {
                              setState(() {
                                _selectedCategoryId = newCategoryId;
                                _selectedSubCategoryName = null;
                                _selectedSubCategoryIconName = null;
                              });
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.paperCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.line, strokeAlign: BorderSide.strokeAlignCenter),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppTheme.gold, size: 18),
                            const SizedBox(width: 8),
                            Text('Create Custom Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                          ],
                        ),
                      ),
                    );
                  }

                  final cat = categories[idx];
                  final isSelected = _selectedCategoryId == cat.id;
                  final catColor = AppTheme.getCategoryColor(cat.id, cat.name);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedSubCategoryName = null;
                        _selectedSubCategoryIconName = null;
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.ink : AppTheme.paperCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppTheme.ink : AppTheme.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.goldSoft.withValues(alpha: 0.2) : catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                IconUtils.getIcon(IconUtils.getIconName(cat.icon), categoryName: cat.name),
                                size: 16,
                                color: isSelected ? AppTheme.goldSoft : catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded, color: AppTheme.goldSoft, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategorySection(BuildContext context, Category category) {
    final catColor = AppTheme.getCategoryColor(category.id, category.name);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Sub-category (Optional)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...category.subCategories.map((sub) {
                final isSelected = _selectedSubCategoryName == sub.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSubCategoryName = null;
                          _selectedSubCategoryIconName = null;
                        } else {
                          _selectedSubCategoryName = sub.name;
                          _selectedSubCategoryIconName = IconUtils.getIconName(sub.icon);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withOpacity(0.15) : AppTheme.paper2,
                        border: Border.all(
                          color: isSelected ? catColor : AppTheme.line,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconUtils.getIcon(IconUtils.getIconName(sub.icon), categoryName: sub.name),
                            size: 14,
                            color: isSelected ? catColor : AppTheme.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sub.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.textDark : AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // Trailing "+" chip
              InkWell(
                onTap: () => _showAddSubCategoryDialog(context, category),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    border: Border.all(color: AppTheme.line, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: AppTheme.muted),
                      const SizedBox(width: 6),
                      Text(
                        'Add',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddCategoryTile(BuildContext context, CategoryType type) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => CreateCategorySheet(
            categoryProvider: context.read<CategoryProvider>(),
            type: type,
            onSave: (newCategoryId) {
              setState(() {
                _selectedCategoryId = newCategoryId;
                _selectedSubCategoryName = null;
                _selectedSubCategoryIconName = null;
              });
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.paper2,
          border: Border.all(
            color: AppTheme.line,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppTheme.muted, size: 18),
            const SizedBox(height: 4),
            Text(
              'Add Category',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController();
    String? selectedIconName = IconUtils.availableIconNames.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.paperCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'New Sub-category',
                style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sub-category Name',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Coffee, Uber',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Icon',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      width: 300,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: IconUtils.availableIconNames.length,
                        itemBuilder: (context, index) {
                          final name = IconUtils.availableIconNames[index];
                          final icon = IconUtils.getIcon(name);
                          final isSelected = selectedIconName == name;
                          final catColor = AppTheme.getCategoryColor(category.id, category.name);
                          return InkWell(
                            onTap: () => setDialogState(() => selectedIconName = name),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? catColor.withOpacity(0.15) : AppTheme.paper2,
                                border: Border.all(
                                  color: isSelected ? catColor : AppTheme.line,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: isSelected ? catColor : AppTheme.muted, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
                ),
                ElevatedButton(
                  onPressed: nameController.text.trim().isEmpty || selectedIconName == null
                      ? null
                      : () async {
                          final subName = nameController.text.trim();
                          final subIcon = IconUtils.getIcon(selectedIconName);
                          final newSub = SubCategory(name: subName, icon: subIcon);

                          final updatedSubs = List<SubCategory>.from(category.subCategories)..add(newSub);
                          final updatedCategory = Category(
                            id: category.id,
                            name: category.name,
                            type: category.type,
                            icon: category.icon,
                            subCategories: updatedSubs,
                          );

                          try {
                            await context.read<CategoryProvider>().update(updatedCategory);
                            
                            setState(() {
                              _selectedSubCategoryName = subName;
                              _selectedSubCategoryIconName = selectedIconName;
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error adding subcategory: $e')),
                              );
                            }
                          }
                        },
                  child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
