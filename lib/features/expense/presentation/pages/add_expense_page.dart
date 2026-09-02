import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:expense_tracker/core/utils/haptics_service.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_category_selector.dart';
import 'package:expense_tracker/features/expense/domain/entities/split_details.dart';
import 'package:expense_tracker/features/expense/domain/services/frequency_suggestion_service.dart';

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
  String? _attachmentPath;
  String? _attachmentName;
  String? _attachmentType;

  // Plan Mode specific fields
  DateTime _planStartDate = DateTime.now();
  DateTime _planEndDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  DateTime _recurringNextDueDate = DateTime.now().add(const Duration(days: 30));
  // Payment Method state
  late TextEditingController _customPaymentMethodController;

  // FocusNode for Title autocomplete
  final FocusNode _titleFocusNode = FocusNode();

  // In-Transaction Split Bill fields
  bool _isSplit = false;
  String _splitType = 'equally'; // 'equally' or 'contribute'
  String _splitPaidBy = 'me'; // 'me' or 'other'
  int _splitPeopleCount = 2;
  late TextEditingController _splitPeopleCountController;
  late TextEditingController _splitPaidByOtherController;
  late TextEditingController _totalBillAmountController;
  late TextEditingController _userShareManualController;
  final List<TextEditingController> _participantNameControllers = [];
  final List<TextEditingController> _participantAmountControllers = [];
  final List<bool> _participantSettledList = [];

  void _addSplitParticipant([String name = '', double amount = 0.0, bool isSettled = false]) {
    _participantNameControllers.add(TextEditingController(text: name));
    _participantAmountControllers.add(TextEditingController(text: amount > 0 ? amount.toStringAsFixed(2) : ''));
    _participantSettledList.add(isSettled);
  }

  void _removeSplitParticipant(int index) {
    if (index >= 0 && index < _participantNameControllers.length) {
      _participantNameControllers[index].dispose();
      _participantAmountControllers[index].dispose();
      _participantNameControllers.removeAt(index);
      _participantAmountControllers.removeAt(index);
      _participantSettledList.removeAt(index);
    }
  }

  String _formatNumeric(double val) {
    if (val <= 0) return '';
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  void _updateQuickSplit() {
    final totalBill = double.tryParse(_totalBillAmountController.text.trim()) ?? 0.0;
    if (totalBill <= 0 || _splitPeopleCount < 1) return;
    if (_splitType == 'equally') {
      final share = totalBill / _splitPeopleCount;
      final text = _formatNumeric(share);
      _amountController.text = text;
      _userShareManualController.text = text;
    } else {
      if (_userShareManualController.text.trim().isEmpty) {
        final defaultShare = totalBill / _splitPeopleCount;
        final text = _formatNumeric(defaultShare);
        _userShareManualController.text = text;
        _amountController.text = text;
      } else {
        final contrib = double.tryParse(_userShareManualController.text.trim()) ?? (totalBill / _splitPeopleCount);
        _amountController.text = _formatNumeric(contrib);
      }
    }
  }

  void _recalculateSplitShares({bool splitEqually = false}) {
    _updateQuickSplit();
  }

  void _applySuggestion(ExpenseSuggestion suggestion) {
    setState(() {
      _titleController.text = suggestion.title;
      _selectedCategoryId = suggestion.categoryId;
      _selectedSubCategoryName = suggestion.subCategory;
      _selectedSubCategoryIconName = suggestion.subCategoryIcon;
      _selectedAccountId = suggestion.accountId;
      _mode = suggestion.type == CategoryType.income ? TransactionMode.income : TransactionMode.expense;
      if (_amountController.text.isEmpty || _amountController.text == '0.00' || _amountController.text == '0') {
        _amountController.text = suggestion.typicalAmount.toStringAsFixed(2);
      }
    });
  }

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
      case 'six_months':
        int nextYear = now.year;
        int nextMonth = now.month + 6;
        if (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }
        int nextDay = now.day;
        int daysInNextMonth = _getDaysInMonth(nextYear, nextMonth);
        if (nextDay > daysInNextMonth) {
          nextDay = daysInNextMonth;
        }
        _recurringNextDueDate = DateTime(nextYear, nextMonth, nextDay, now.hour, now.minute, now.second);
        break;
      case 'yearly':
        _recurringNextDueDate = DateTime(now.year + 1, now.month, now.day, now.hour, now.minute, now.second);
        break;
    }
  }

  Future<void> _pickAttachment(String source) async {
    try {
      if (source == 'camera') {
        final picker = ImagePicker();
        final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (photo != null) {
          setState(() {
            _attachmentPath = photo.path;
            _attachmentName = photo.name;
            _attachmentType = 'image';
          });
        }
      } else if (source == 'gallery') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (image != null) {
          setState(() {
            _attachmentPath = image.path;
            _attachmentName = image.name;
            _attachmentType = 'image';
          });
        }
      } else if (source == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'txt'],
        );
        if (result != null && result.files.single.path != null) {
          final file = result.files.single;
          setState(() {
            _attachmentPath = file.path;
            _attachmentName = file.name;
            _attachmentType = file.extension == 'pdf' ? 'pdf' : 'file';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach proof: $e'), backgroundColor: AppTheme.brick),
        );
      }
    }
  }

  Future<void> _confirmRemoveAttachment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: dialogCtx.line),
        ),
        title: Text('Remove Proof Attachment?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: dialogCtx.textPrimary)),
        content: Text(
          'Removing this attachment will detach the file link. The transaction itself will NOT be deleted.',
          style: TextStyle(color: dialogCtx.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: TextStyle(color: dialogCtx.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: dialogCtx.brick),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _attachmentPath = null;
        _attachmentName = null;
        _attachmentType = null;
      });
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
    _attachmentPath = widget.expenseToEdit?.attachmentUrl;
    _attachmentName = widget.expenseToEdit?.attachmentName;
    _attachmentType = widget.expenseToEdit?.attachmentType;

    _splitPaidByOtherController = TextEditingController();
    _totalBillAmountController = TextEditingController();
    _splitPeopleCountController = TextEditingController(text: '2');
    _userShareManualController = TextEditingController(
      text: widget.expenseToEdit?.amount.toString() ?? '',
    );

    _customPaymentMethodController = TextEditingController();
    if (_selectedPaymentMethod != null &&
        !['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer'].contains(_selectedPaymentMethod)) {
      _customPaymentMethodController.text = _selectedPaymentMethod!;
    }

    if (widget.expenseToEdit?.splitDetails != null) {
      final split = widget.expenseToEdit!.splitDetails!;
      _isSplit = split.isSplit;
      _splitPaidBy = split.isPaidByMe ? 'me' : 'other';
      if (!split.isPaidByMe) {
        _splitPaidByOtherController.text = split.paidBy;
      }
      _totalBillAmountController.text = split.totalBillAmount.toStringAsFixed(2);
      if (split.splits.isNotEmpty) {
        _splitPeopleCount = split.splits.length + 1;
        _splitPeopleCountController.text = _splitPeopleCount.toString();
        for (final s in split.splits) {
          _addSplitParticipant(s.name, s.amount, s.isSettled);
        }
      }
    }

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
    _titleFocusNode.dispose();
    _customPaymentMethodController.dispose();
    _splitPeopleCountController.dispose();
    _splitPaidByOtherController.dispose();
    _totalBillAmountController.dispose();
    _userShareManualController.dispose();
    for (final c in _participantNameControllers) {
      c.dispose();
    }
    for (final c in _participantAmountControllers) {
      c.dispose();
    }
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

  void _showMissingFieldsDialog(List<String> missingFields) {
    HapticsService.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: ctx.line),
        ),
        icon: Icon(Icons.warning_amber_rounded, color: ctx.brick, size: 38),
        title: Text(
          'Missing Required Fields',
          style: GoogleFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: ctx.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please complete the following required fields before saving:',
              style: GoogleFonts.inter(fontSize: 12, color: ctx.textMuted),
            ),
            const SizedBox(height: 12),
            ...missingFields.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 15, color: ctx.brick),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ctx.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctx.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Got It', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    debugPrint('[AddExpensePage] _saveExpense() called');
    if (_isSaving) {
      debugPrint('[AddExpensePage] _isSaving is true, aborting duplicate save');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    // Collect all missing mandatory fields for explicit popup warning
    final missingFields = <String>[];

    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      missingFields.add('Amount');
    }

    if (_titleController.text.trim().isEmpty) {
      missingFields.add('Title / Merchant');
    }

    if (_mode != TransactionMode.plan && _mode != TransactionMode.transfer) {
      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        missingFields.add('Category');
      }
      if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
        missingFields.add('Account');
      }
      final resolvedMethod = _selectedPaymentMethod == 'Custom'
          ? _customPaymentMethodController.text.trim()
          : _selectedPaymentMethod;
      if (resolvedMethod == null || resolvedMethod.isEmpty) {
        missingFields.add('Payment Method');
      }
    } else if (_mode == TransactionMode.transfer) {
      if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
        missingFields.add('From Account');
      }
      if (_selectedToAccountId == null || _selectedToAccountId!.isEmpty) {
        missingFields.add('To Account');
      }
    }

    if (missingFields.isNotEmpty) {
      _showMissingFieldsDialog(missingFields);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AddExpensePage] Form validation failed');
      return;
    }
    debugPrint('[AddExpensePage] Form validation succeeded');

    setState(() {
      _isSaving = true;
    });

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
          paymentMethod: _selectedPaymentMethod == 'Custom'
              ? _customPaymentMethodController.text.trim()
              : _selectedPaymentMethod,
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
        SplitDetails? splitDetails;
        PaymentStatus effectivePaymentStatus = _paymentStatus;

        if (_mode == TransactionMode.expense && _isSplit) {
          final totalBill = double.tryParse(_totalBillAmountController.text.trim()) ?? double.parse(_amountController.text.trim());
          final myShare = double.tryParse(_amountController.text.trim()) ?? (totalBill / (_splitPeopleCount > 0 ? _splitPeopleCount : 2));
          final splits = <SplitItem>[];

          final othersCount = _splitPeopleCount > 1 ? _splitPeopleCount - 1 : 1;
          final remainingForOthers = (totalBill - myShare).clamp(0.0, totalBill);
          final eachOtherShare = remainingForOthers / othersCount;

          for (int i = 0; i < othersCount; i++) {
            String name = 'Person ${i + 1}';
            if (i < _participantNameControllers.length && _participantNameControllers[i].text.trim().isNotEmpty) {
              name = _participantNameControllers[i].text.trim();
            }
            final isSettled = (i < _participantSettledList.length) ? _participantSettledList[i] : false;
            splits.add(SplitItem(
              name: name,
              amount: eachOtherShare,
              isSettled: isSettled,
            ));
          }

          final paidBy = _splitPaidBy == 'me'
              ? 'me'
              : (_splitPaidByOtherController.text.trim().isNotEmpty ? _splitPaidByOtherController.text.trim() : 'Friend');

          splitDetails = SplitDetails(
            isSplit: true,
            paidBy: paidBy,
            totalBillAmount: totalBill,
            amountOwedToPayer: _splitPaidBy == 'me' ? 0.0 : myShare,
            splits: splits,
          );

          if (_splitPaidBy != 'me' && widget.expenseToEdit == null) {
            effectivePaymentStatus = PaymentStatus.pending;
          }
        }

        final finalPaymentMethod = _selectedPaymentMethod == 'Custom'
            ? _customPaymentMethodController.text.trim()
            : _selectedPaymentMethod;

        final expense = Expense(
          id: widget.expenseToEdit?.id ?? const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim(),
          accountId: _selectedAccountId!,
          subCategory: _selectedSubCategoryName,
          subCategoryIcon: _selectedSubCategoryIconName,
          type: _mode == TransactionMode.income ? CategoryType.income : CategoryType.expense,
          planId: _selectedPlanId,
          paymentStatus: effectivePaymentStatus,
          paymentMethod: finalPaymentMethod,
          payerPayee: _payerPayeeController.text.trim().isNotEmpty ? _payerPayeeController.text.trim() : null,
          attachmentUrl: _attachmentPath,
          attachmentName: _attachmentName,
          attachmentType: _attachmentType,
          splitDetails: splitDetails,
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: dialogCtx.line),
        ),
        title: Text('Delete Transaction', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: dialogCtx.textPrimary)),
        content: Text('Are you sure you want to delete this transaction?', style: TextStyle(color: dialogCtx.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: TextStyle(color: dialogCtx.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: dialogCtx.brick),
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
    final expenseProvider = context.watch<ExpenseProvider>();

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
        ? context.brick 
        : (_mode == TransactionMode.income ? context.emerald : context.gold);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          widget.expenseToEdit != null ? 'Edit Transaction' : (_mode == TransactionMode.plan ? 'New Goal' : 'New Transaction'),
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: context.textPrimary),
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
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(context, 'Expense', TransactionMode.expense),
                      _buildToggleButton(context, 'Income', TransactionMode.income),
                      _buildToggleButton(context, 'Transfer', TransactionMode.transfer),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Smart Frequent Suggestions Pill Chips
              if (widget.expenseToEdit == null && _mode != TransactionMode.plan && _mode != TransactionMode.transfer)
                _buildFrequentSuggestions(context, expenseProvider),

              // Balanced Space Grotesk amount display
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currencySymbol,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: displayColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _amountController,
                        style: GoogleFonts.spaceGrotesk(
                           fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.spaceGrotesk(color: context.textMuted.withValues(alpha: 0.3)),
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
              const SizedBox(height: 14),

              if (_mode == TransactionMode.plan) ...[
                // Plan form
                _buildSectionLabel(context, 'Goal Title'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Summer Vacation',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel(context, 'Start Date'),
                _buildDateTile(context, _planStartDate, (date) {
                  setState(() {
                    _planStartDate = date;
                  });
                }),
                const SizedBox(height: 16),
                _buildSectionLabel(context, 'Financed Amount (Optional)'),
                TextFormField(
                  controller: _financedAmountController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5000.00',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel(context, 'End Date'),
                _buildDateTile(context, _planEndDate, (date) {
                  setState(() {
                    _planEndDate = date;
                  });
                }),
              ] else if (_mode == TransactionMode.transfer) ...[
                // Transfer form
                _buildSectionLabel(context, 'From Account'),
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  dropdownColor: context.cardBg,
                  style: GoogleFonts.inter(color: context.textPrimary),
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
                          Text(acc.name, style: GoogleFonts.inter(color: context.textPrimary)),
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

                _buildSectionLabel(context, 'To Account'),
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedToAccountId) ? _selectedToAccountId : null,
                  dropdownColor: context.cardBg,
                  style: GoogleFonts.inter(color: context.textPrimary),
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
                          Text(acc.name, style: GoogleFonts.inter(color: context.textPrimary)),
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

                _buildSectionLabel(context, 'Description (Optional)'),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Transfer to Savings',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionLabel(context, 'Date'),
                _buildDateTile(context, _selectedDate, (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                }),
                const SizedBox(height: 16),

                _buildSectionLabel(context, 'Notes (Optional)'),
                TextFormField(
                  controller: _noteController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
              ] else ...[
                // Transaction Form (Expense/Income)
                InkLedgerCategorySelector(
                  categoryType: currentCategoryType,
                  selectedCategoryId: _selectedCategoryId,
                  selectedSubCategoryName: _selectedSubCategoryName,
                  onCategorySelected: (catId, subCat) {
                    setState(() {
                      _selectedCategoryId = catId;
                      _selectedSubCategoryName = subCat;
                    });
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildSectionLabel(context, 'Account'),
                        const SizedBox(width: 4),
                        Text('*', style: GoogleFonts.inter(color: context.brick, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
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
                            color: context.surface2,
                            border: Border.all(color: context.line),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconUtils.getIcon('cash'), size: 12, color: context.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Cash',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.textMuted,
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
                  dropdownColor: context.cardBg,
                  style: GoogleFonts.inter(color: context.textPrimary),
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
                          Text(acc.name, style: GoogleFonts.inter(color: context.textPrimary)),
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

                _buildSectionLabel(context, 'Title / Merchant'),
                _buildTitleAutocompleteField(context, expenseProvider),
                const SizedBox(height: 16),

                _buildSectionLabel(context, 'Date'),
                _buildDateTile(context, _selectedDate, (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                }),
                const SizedBox(height: 16),

                _buildSectionLabel(context, 'Notes (Optional)'),
                TextFormField(
                  controller: _noteController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                _buildReceiptProofSection(context),
                const SizedBox(height: 12),

                if (_mode == TransactionMode.expense) ...[
                  _buildSplitBillSection(context),
                  const SizedBox(height: 16),
                ],

                _buildSectionLabel(context, 'Payment Status'),
                Container(
                  decoration: BoxDecoration(
                    color: context.surface2,
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
                              color: _paymentStatus == PaymentStatus.settled ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Settled',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _paymentStatus == PaymentStatus.settled ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft) : context.textMuted,
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
                              color: _paymentStatus == PaymentStatus.pending ? context.gold : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pending',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _paymentStatus == PaymentStatus.pending ? Colors.white : context.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildPaymentMethodSelector(context),
                const SizedBox(height: 16),

                _buildSectionLabel(context, _mode == TransactionMode.income ? 'Payer / Source (Optional)' : 'Payee / Recipient (Optional)'),
                TextFormField(
                  controller: _payerPayeeController,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: _mode == TransactionMode.income ? 'e.g. Client or Employer' : 'e.g. Restaurant or Merchant',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                if (tripPlans.isNotEmpty || goals.isNotEmpty) ...[
                  _buildSectionLabel(context, 'Link to Plan / Goal (Optional)'),
                  DropdownButtonFormField<String>(
                    value: (tripPlans.any((p) => p.id == _selectedPlanId) ||
                            goals.any((g) => g.id == _selectedPlanId) ||
                            _selectedPlanId == null)
                        ? _selectedPlanId
                        : null,
                    dropdownColor: context.cardBg,
                    style: GoogleFonts.inter(color: context.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'None (Unlinked transaction)',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (Unlinked transaction)'),
                      ),
                      ...tripPlans.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('TRIP', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.gold)),
                              ),
                              const SizedBox(width: 8),
                              Text(p.title, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                            ],
                          ),
                        );
                      }),
                      ...goals.map((g) {
                        return DropdownMenuItem<String>(
                          value: g.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.emerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('GOAL', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.emerald)),
                              ),
                              const SizedBox(width: 8),
                              Text(g.title, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                            ],
                          ),
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
                        color: context.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically track this transaction schedule',
                      style: GoogleFonts.inter(color: context.textMuted, fontSize: 12),
                    ),
                    value: _isRecurring,
                    activeTrackColor: _mode == TransactionMode.income ? context.emerald : context.gold,
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
                    _buildSectionLabel(context, 'Frequency'),
                    DropdownButtonFormField<String>(
                      value: _recurringFrequency,
                      dropdownColor: context.cardBg,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Select Frequency',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'six_months', child: Text('Every 6 Months')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
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
                    _buildSectionLabel(context, 'Next Due Date'),
                    _buildDateTile(context, _recurringNextDueDate, (date) {
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
                  backgroundColor: context.gold,
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
                  style: TextButton.styleFrom(foregroundColor: context.brick),
                  child: const Text('Delete Transaction'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildToggleButton(BuildContext context, String label, TransactionMode mode) {
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
            color: isActive ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft) : context.textMuted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: context.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDateTile(BuildContext context, DateTime date, Function(DateTime) onDatePicked) {
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: context.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormatter.format(date),
              style: GoogleFonts.inter(color: context.textPrimary),
            ),
            Icon(Icons.calendar_today_rounded, size: 18, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptProofSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, 'Receipt or Proof (Optional)'),
        if (_attachmentPath != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.line),
                  ),
                  child: _attachmentType == 'image' && File(_attachmentPath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_attachmentPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.description_outlined, color: context.gold, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _attachmentName ?? 'Attached Proof',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _attachmentType?.toUpperCase() ?? 'FILE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: context.textMuted),
                  color: context.cardBg,
                  onSelected: (val) {
                    if (val == 'replace_gallery') _pickAttachment('gallery');
                    if (val == 'replace_camera') _pickAttachment('camera');
                    if (val == 'replace_file') _pickAttachment('file');
                    if (val == 'remove') _confirmRemoveAttachment();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'replace_gallery',
                      child: Text('Replace from Gallery', style: TextStyle(color: context.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: 'replace_camera',
                      child: Text('Replace from Camera', style: TextStyle(color: context.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: 'replace_file',
                      child: Text('Replace with File', style: TextStyle(color: context.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove Proof', style: TextStyle(color: context.brick)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAttachment('gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: context.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.photo_library_outlined, size: 16, color: context.gold),
                  label: Text('Gallery', style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAttachment('camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: context.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.camera_alt_outlined, size: 16, color: context.gold),
                  label: Text('Camera', style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAttachment('file'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: context.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.attach_file_rounded, size: 16, color: context.gold),
                  label: Text('File', style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactCategorySection(BuildContext context, List<Category> filteredCategories, CategoryType currentCategoryType, Category? selectedCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel(context, 'Category'),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Manage categories',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.gold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: context.gold),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Step 1: Parent Categories Short Scrollable Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...filteredCategories.map((category) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.line,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconUtils.getIcon(IconUtils.getIconName(category.icon), categoryName: category.name),
                          color: isSelected ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft) : catColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? (context.isDark ? const Color(0xFF121C15) : Colors.white) : context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // Inline Add Category option
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CreateCategorySheet(
                      categoryProvider: context.read<CategoryProvider>(),
                      type: currentCategoryType,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: context.gold),
                      const SizedBox(width: 3),
                      Text('New', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.gold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Step 2: Selected Parent's Subcategories (Appears only after selecting parent)
        if (selectedCategory != null)
          _buildSubCategorySection(context, selectedCategory),
      ],
    );
  }

  Widget _buildSubCategorySection(BuildContext context, Category category) {
    final catColor = AppTheme.getCategoryColor(category.id, category.name);
    final noSubSelected = _selectedSubCategoryName == null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, '${category.name} Subcategories'),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // No subcategory chip
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubCategoryName = null;
                      _selectedSubCategoryIconName = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: noSubSelected ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.surface2,
                      border: Border.all(
                        color: noSubSelected ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.line,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No subcategory',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: noSubSelected ? FontWeight.bold : FontWeight.w500,
                          color: noSubSelected ? (context.isDark ? const Color(0xFF121C15) : Colors.white) : context.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Existing Subcategories
              ...category.subCategories.map((sub) {
                final isSelected = _selectedSubCategoryName == sub.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withValues(alpha: 0.15) : context.surface2,
                        border: Border.all(
                          color: isSelected ? catColor : context.line,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconUtils.getIcon(IconUtils.getIconName(sub.icon), categoryName: sub.name),
                            size: 13,
                            color: isSelected ? catColor : context.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            sub.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? context.textPrimary : context.textPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // "+ Add subcategory" action chip (Expense only)
              if (category.type != CategoryType.income)
                InkWell(
                  onTap: () => _showAddSubCategoryDialog(context, category),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      border: Border.all(color: context.line, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: context.gold),
                        const SizedBox(width: 4),
                        Text(
                          'Add subcategory',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.gold,
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
          color: context.surface2,
          border: Border.all(
            color: context.line,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: context.textMuted, size: 18),
            const SizedBox(height: 4),
            Text(
              'Add Category',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: context.textMuted,
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
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogCtx.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: dialogCtx.line),
              ),
              title: Text(
                'New Sub-category',
                style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: dialogCtx.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sub-category Name',
                      style: GoogleFonts.inter(fontSize: 12, color: dialogCtx.textMuted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(color: dialogCtx.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Coffee, Uber',
                        hintStyle: GoogleFonts.inter(color: dialogCtx.textMuted),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Icon',
                      style: GoogleFonts.inter(fontSize: 12, color: dialogCtx.textMuted, fontWeight: FontWeight.bold),
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
                                color: isSelected ? catColor.withValues(alpha: 0.15) : dialogCtx.surface2,
                                border: Border.all(
                                  color: isSelected ? catColor : dialogCtx.line,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: isSelected ? catColor : dialogCtx.textMuted, size: 20),
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: dialogCtx.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogCtx.isDark ? AppTheme.goldSoft : AppTheme.ink,
                    foregroundColor: dialogCtx.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft,
                  ),
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

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error adding subcategory: $e')),
                              );
                            }
                          }
                        },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFrequentSuggestions(BuildContext context, ExpenseProvider provider) {
    final suggestions = provider.getTopFrequentSuggestions(maxResults: 5);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12, color: context.gold),
              const SizedBox(width: 4),
              Text(
                'FREQUENT QUICK PICKS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: context.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: s.type == CategoryType.income
                          ? context.emerald.withValues(alpha: 0.2)
                          : context.brick.withValues(alpha: 0.2),
                      radius: 9,
                      child: Icon(
                        s.type == CategoryType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 10,
                        color: s.type == CategoryType.income ? context.emerald : context.brick,
                      ),
                    ),
                    label: Text(
                      s.title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    backgroundColor: context.surface2,
                    side: BorderSide(color: context.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    onPressed: () {
                      HapticsService.selection();
                      _applySuggestion(s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAutocompleteField(BuildContext context, ExpenseProvider provider) {
    return RawAutocomplete<ExpenseSuggestion>(
      textEditingController: _titleController,
      focusNode: _titleFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().length < 2) {
          return const Iterable<ExpenseSuggestion>.empty();
        }
        return provider.getFilteredTitleSuggestions(textEditingValue.text.trim());
      },
      displayStringForOption: (ExpenseSuggestion option) => option.title,
      onSelected: (ExpenseSuggestion selection) {
        HapticsService.selection();
        _applySuggestion(selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.inter(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Starbucks, Supermarket, Rent',
            hintStyle: GoogleFonts.inter(color: context.textMuted),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: context.textMuted),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: context.cardBg,
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.goldLine),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: context.line),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${option.type.name.toUpperCase()} • ${option.usageCount} logs • ~${CurrencyFormatter.format(option.typicalAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                    ),
                    trailing: Icon(Icons.north_west_rounded, size: 14, color: context.gold),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodSelector(BuildContext context) {
    final standardMethods = ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Custom'];
    final isCustomSelected = _selectedPaymentMethod != null &&
        !['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer'].contains(_selectedPaymentMethod);
    final currentDropdownValue = isCustomSelected ? 'Custom' : _selectedPaymentMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel(context, 'Payment Method'),
            const SizedBox(width: 4),
            Text('*', style: GoogleFonts.inter(color: context.brick, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: standardMethods.contains(currentDropdownValue) ? currentDropdownValue : null,
          dropdownColor: context.cardBg,
          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Select payment method',
            hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
          ),
          items: [
            DropdownMenuItem(
              value: 'Cash',
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: context.emerald),
                  const SizedBox(width: 10),
                  Text('Cash', style: GoogleFonts.inter(color: context.textPrimary)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Credit Card',
              child: Row(
                children: [
                  Icon(Icons.credit_card_rounded, size: 16, color: context.gold),
                  const SizedBox(width: 10),
                  Text('Credit Card', style: GoogleFonts.inter(color: context.textPrimary)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Debit Card',
              child: Row(
                children: [
                  Icon(Icons.credit_score_rounded, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text('Debit Card', style: GoogleFonts.inter(color: context.textPrimary)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Bank Transfer',
              child: Row(
                children: [
                  Icon(Icons.account_balance_rounded, size: 16, color: Colors.purpleAccent),
                  const SizedBox(width: 10),
                  Text('Bank Transfer', style: GoogleFonts.inter(color: context.textPrimary)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Custom',
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: context.gold),
                  const SizedBox(width: 10),
                  Text('Custom', style: GoogleFonts.inter(color: context.textPrimary)),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            HapticsService.selection();
            setState(() {
              if (val == 'Custom') {
                _selectedPaymentMethod = _customPaymentMethodController.text.trim().isNotEmpty
                    ? _customPaymentMethodController.text.trim()
                    : 'Custom';
              } else {
                _selectedPaymentMethod = val;
              }
            });
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Please select a payment method' : null,
        ),
        if (currentDropdownValue == 'Custom' || isCustomSelected) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _customPaymentMethodController,
            style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter custom payment method (e.g. bKash, Apple Pay, PayPal)',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
              prefixIcon: Icon(Icons.edit_note_rounded, size: 18, color: context.gold),
            ),
            onChanged: (val) {
              setState(() {
                _selectedPaymentMethod = val.trim().isNotEmpty ? val.trim() : 'Custom';
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSplitBillSection(BuildContext context) {
    if (_mode != TransactionMode.expense) return const SizedBox.shrink();

    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;
    final totalBill = double.tryParse(_totalBillAmountController.text.trim()) ?? 0.0;
    final myAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final othersCount = _splitPeopleCount > 1 ? _splitPeopleCount - 1 : 1;
    final remainingForOthers = (totalBill - myAmount).clamp(0.0, totalBill);
    final eachOtherShare = remainingForOthers / othersCount;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: _isSplit ? context.gold : context.line,
          width: _isSplit ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSplit ? context.gold.withValues(alpha: 0.15) : context.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.call_split_rounded,
                color: _isSplit ? context.gold : context.textMuted,
                size: 20,
              ),
            ),
            title: Text(
              'Split Bill with Friends / Group',
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              _isSplit
                  ? (_splitType == 'equally' ? 'Split equally across group' : 'Custom partial contribution')
                  : 'Track counterparties and shares',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textMuted,
              ),
            ),
            trailing: Switch.adaptive(
              value: _isSplit,
              activeColor: context.gold,
              onChanged: (val) {
                HapticsService.selection();
                setState(() {
                  _isSplit = val;
                  if (_isSplit) {
                    if (_totalBillAmountController.text.isEmpty && _amountController.text.isNotEmpty) {
                      _totalBillAmountController.text = _amountController.text;
                    }
                    _updateQuickSplit();
                  }
                });
              },
            ),
          ),
          if (_isSplit) ...[
            Divider(height: 1, color: context.line),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Split Mode: Equally vs Contribute (Partially)
                  _buildSectionLabel(context, 'Split Type'),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setState(() {
                                _splitType = 'equally';
                                _updateQuickSplit();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _splitType == 'equally'
                                    ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 15,
                                    color: _splitType == 'equally'
                                        ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                        : context.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Equally',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _splitType == 'equally'
                                          ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                          : context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setState(() {
                                _splitType = 'contribute';
                                _updateQuickSplit();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _splitType == 'contribute'
                                    ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.volunteer_activism_outlined,
                                    size: 15,
                                    color: _splitType == 'contribute'
                                        ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                        : context.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Contribute',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _splitType == 'contribute'
                                          ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                          : context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Who Paid
                  _buildSectionLabel(context, 'Who Paid the Bill?'),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setState(() => _splitPaidBy = 'me');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _splitPaidBy == 'me'
                                    ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'I Paid Full Bill',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _splitPaidBy == 'me'
                                        ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                        : context.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setState(() => _splitPaidBy = 'other');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _splitPaidBy == 'other'
                                    ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Someone Else Paid',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _splitPaidBy == 'other'
                                        ? (context.isDark ? const Color(0xFF131A15) : Colors.white)
                                        : context.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_splitPaidBy == 'other') ...[
                    const SizedBox(height: 12),
                    _buildSectionLabel(context, "Payer's Name / Group"),
                    TextFormField(
                      controller: _splitPaidByOtherController,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Alice, Bob, Office Group',
                        hintStyle: GoogleFonts.inter(color: context.textMuted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 3. Total Bill Amount
                  _buildSectionLabel(context, 'Total Bill Amount ($currencySymbol)'),
                  TextFormField(
                    controller: _totalBillAmountController,
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.spaceGrotesk(color: context.textMuted),
                      suffixIcon: _splitType == 'equally'
                          ? TextButton.icon(
                              icon: Icon(Icons.refresh_rounded, size: 14, color: context.gold),
                              label: Text('Recalculate', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.gold)),
                              onPressed: () {
                                HapticsService.selection();
                                setState(() => _updateQuickSplit());
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() => _updateQuickSplit());
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. Direct Headcount Stepper & Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(context, 'Total People to Split'),
                          Text(
                            'Including yourself',
                            style: GoogleFonts.inter(fontSize: 10, color: context.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_rounded, size: 18, color: context.gold),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                if (_splitPeopleCount > 2) {
                                  HapticsService.selection();
                                  setState(() {
                                    _splitPeopleCount--;
                                    _splitPeopleCountController.text = _splitPeopleCount.toString();
                                    _updateQuickSplit();
                                  });
                                }
                              },
                            ),
                            SizedBox(
                              width: 42,
                              child: TextFormField(
                                controller: _splitPeopleCountController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  final count = int.tryParse(val.trim());
                                  if (count != null && count >= 2) {
                                    setState(() {
                                      _splitPeopleCount = count;
                                      _updateQuickSplit();
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_rounded, size: 18, color: context.gold),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                HapticsService.selection();
                                setState(() {
                                  _splitPeopleCount++;
                                  _splitPeopleCountController.text = _splitPeopleCount.toString();
                                  _updateQuickSplit();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Your Share Display (Non-editable in Equally, Editable in Contribute)
                  if (_splitType == 'equally') ...[
                    _buildSectionLabel(context, _splitPaidBy == 'me' ? 'Your Equal Share' : 'You Owe (Equal Share)'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 16, color: context.gold),
                              const SizedBox(width: 8),
                              Text(
                                'Fixed Equal Share:',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                              ),
                            ],
                          ),
                          Text(
                            '$currencySymbol ${_amountController.text}',
                            style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: context.gold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, left: 4.0),
                      child: Text(
                        'Automatically calculated: $currencySymbol${_totalBillAmountController.text} ÷ $_splitPeopleCount = $currencySymbol${_amountController.text} each (Equal mode is non-editable)',
                        style: GoogleFonts.inter(fontSize: 10, color: context.textMuted),
                      ),
                    ),
                  ] else ...[
                    // Contribute mode: Editable direct contribution
                    _buildSectionLabel(context, _splitPaidBy == 'me' ? 'Your Contribution (Editable)' : 'You Owe / Contribute (Editable)'),
                    TextFormField(
                      controller: _userShareManualController,
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: context.gold),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '$currencySymbol ',
                        prefixStyle: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: context.gold),
                        hintText: '0',
                        hintStyle: GoogleFonts.spaceGrotesk(color: context.textMuted),
                        helperText: 'Enter your contribution amount • Remaining amount is shared by others',
                        helperStyle: GoogleFonts.inter(fontSize: 10, color: context.textMuted),
                      ),
                      onChanged: (val) {
                        final amt = double.tryParse(val.trim());
                        setState(() {
                          if (amt != null) {
                            _amountController.text = val.trim();
                          } else if (val.trim().isEmpty) {
                            _amountController.text = '0';
                          }
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 6. Optional Participant Names Accordion
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      dense: true,
                      title: Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 16, color: context.gold),
                          const SizedBox(width: 6),
                          Text(
                            'Participant Names (Optional)',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.gold),
                          ),
                        ],
                      ),
                      children: [
                        const SizedBox(height: 4),
                        ...List.generate(othersCount, (index) {
                          while (_participantNameControllers.length < index + 1) {
                            _participantNameControllers.add(TextEditingController(text: 'Person ${index + 1}'));
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextFormField(
                              controller: _participantNameControllers[index],
                              style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Person ${index + 1} Name',
                                labelStyle: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                                hintText: 'e.g. Alice, Bob',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  // 7. Live Summary Pill
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.gold.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _splitPaidBy == 'me'
                                  ? (_splitType == 'equally' ? 'Your Equal Share:' : 'Your Contribution:')
                                  : 'You Owe (${_splitPaidByOtherController.text.trim().isNotEmpty ? _splitPaidByOtherController.text.trim() : 'Payer'}):',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                            Text(
                              '$currencySymbol ${_amountController.text}',
                              style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: context.gold),
                            ),
                          ],
                        ),
                        if (othersCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            _splitPaidBy == 'me'
                                ? 'Remaining $currencySymbol${remainingForOthers.toStringAsFixed(2)} split across $othersCount others (~$currencySymbol${eachOtherShare.toStringAsFixed(2)} each)'
                                : 'Total bill: $currencySymbol${totalBill.toStringAsFixed(2)} • Your share/owe: $currencySymbol${_amountController.text}',
                            style: GoogleFonts.inter(fontSize: 10, color: context.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
