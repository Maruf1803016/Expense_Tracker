import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class EditRecurringTransactionSheet extends StatefulWidget {
  final RecurringTransactionSource source;

  const EditRecurringTransactionSheet({super.key, required this.source});

  @override
  State<EditRecurringTransactionSheet> createState() => _EditRecurringTransactionSheetState();
}

class _EditRecurringTransactionSheetState extends State<EditRecurringTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late String _frequency;
  late DateTime _nextDueDate;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.source.name);
    _amountController = TextEditingController(text: widget.source.expectedAmount.toString());
    _frequency = widget.source.frequency;
    _nextDueDate = widget.source.nextDueDate;
    _selectedCategoryId = widget.source.categoryId;
    _selectedAccountId = widget.source.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _nextDueDate) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updated = RecurringTransactionSource(
        id: widget.source.id,
        name: _nameController.text.trim(),
        expectedAmount: double.parse(_amountController.text.trim()),
        frequency: _frequency,
        nextDueDate: _nextDueDate,
        status: widget.source.status,
        type: widget.source.type,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        createdAt: widget.source.createdAt,
      );

      await context.read<RecurringTransactionProvider>().updateSource(updated);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Recurring source updated'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.brick,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Tracking?'),
        content: const Text(
          'Are you sure you want to delete this recurring source? Historical transactions generated from this source will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Stop Tracking'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<RecurringTransactionProvider>().deleteSource(widget.source.id);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Recurring source removed'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        if (mounted) Navigator.pop(context);
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
    final expenseProvider = context.watch<ExpenseProvider>();
    final targetType = widget.source.type == 'income' ? CategoryType.income : CategoryType.expense;
    final categories = expenseProvider.categories
        .where((c) => c.type == targetType && (targetType != CategoryType.income || c.id != 'other'))
        .toList();
    final accounts = context.watch<AccountProvider>().accounts;

    final isIncome = widget.source.type == 'income';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isIncome ? 'Edit Recurring Income' : 'Edit Recurring Bill',
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Source Name'),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                decoration: InputDecoration(hintText: isIncome ? 'e.g. Monthly Salary' : 'e.g. Rent, Netflix'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Expected Amount'),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Frequency'),
              DropdownButtonFormField<String>(
                value: _frequency,
                dropdownColor: AppTheme.paperCard,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                decoration: const InputDecoration(hintText: 'Select Frequency'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _frequency = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Next Due Date'),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.gold),
                label: Text(
                  '${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}',
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: const BorderSide(color: AppTheme.line),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel(isIncome ? 'Income Category' : 'Expense Category'),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                dropdownColor: AppTheme.paperCard,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                decoration: const InputDecoration(hintText: 'Select Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              _buildLabel(isIncome ? 'Deposit Account' : 'Payment Account'),
              DropdownButtonFormField<String>(
                value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                dropdownColor: AppTheme.paperCard,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                decoration: const InputDecoration(hintText: 'Select Account'),
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
                        Text(acc.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
                child: const Text('Stop Tracking & Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.muted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
