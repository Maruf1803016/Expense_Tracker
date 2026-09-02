import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_category_selector.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class EditRecurringTransactionSheet extends StatefulWidget {
  final RecurringTransactionSource? source;

  const EditRecurringTransactionSheet({super.key, this.source});

  @override
  State<EditRecurringTransactionSheet> createState() => _EditRecurringTransactionSheetState();
}

class _EditRecurringTransactionSheetState extends State<EditRecurringTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late String _type; // 'expense' or 'income'
  late String _frequency;
  late DateTime _nextDueDate;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.source;
    _nameController = TextEditingController(text: s?.name ?? '');
    _amountController = TextEditingController(text: s != null ? s.expectedAmount.toString() : '');
    _type = s?.type ?? 'expense';
    _frequency = s?.frequency ?? 'monthly';
    _nextDueDate = s?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
    _selectedCategoryId = s?.categoryId;
    _selectedAccountId = s?.accountId;
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
      final s = widget.source;
      final newSource = RecurringTransactionSource(
        id: s?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        expectedAmount: double.parse(_amountController.text.trim()),
        frequency: _frequency,
        nextDueDate: _nextDueDate,
        status: s?.status ?? 'active',
        type: _type,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        createdAt: s?.createdAt ?? DateTime.now(),
      );

      if (s == null) {
        await context.read<RecurringTransactionProvider>().addSource(newSource);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Recurring rule added'),
            backgroundColor: context.emerald,
          ),
        );
      } else {
        await context.read<RecurringTransactionProvider>().updateSource(newSource);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Recurring rule updated'),
            backgroundColor: context.emerald,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: context.brick,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.source == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        title: Text('Stop Tracking?', style: TextStyle(color: ctx.textPrimary)),
        content: Text(
          'Are you sure you want to delete this recurring rule? Historical transactions generated from this rule will NOT be deleted.',
          style: TextStyle(color: ctx.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ctx.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.brick),
            child: const Text('Stop Tracking'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<RecurringTransactionProvider>().deleteSource(widget.source!.id);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Recurring rule removed'),
            backgroundColor: context.emerald,
          ),
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.brick,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;

    final isIncome = _type == 'income';
    final isNew = widget.source == null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.line),
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
                    isNew
                        ? (isIncome ? 'Add Recurring Income' : 'Add Recurring Bill')
                        : (isIncome ? 'Edit Recurring Income' : 'Edit Recurring Bill'),
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isNew) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Expense / Bill')),
                        selected: _type == 'expense',
                        selectedColor: context.gold,
                        labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: _type == 'expense' ? Colors.white : context.textMuted,
                        ),
                        onSelected: (val) {
                          HapticsService.selection();
                          if (val) setState(() {
                            _type = 'expense';
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Income')),
                        selected: _type == 'income',
                        selectedColor: context.gold,
                        labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: _type == 'income' ? Colors.white : context.textMuted,
                        ),
                        onSelected: (val) {
                          HapticsService.selection();
                          if (val) setState(() {
                            _type = 'income';
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildLabel('Rule Name'),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: isIncome ? 'e.g. Monthly Salary' : 'e.g. Rent, Netflix',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Expected Amount'),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.spaceGrotesk(color: context.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.spaceGrotesk(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Frequency'),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                dropdownColor: context.cardBg,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Select Frequency',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
                items: [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'biweekly', child: Text('Biweekly', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'semi_annually', child: Text('Every 6 months', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly', style: TextStyle(color: context.textPrimary))),
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
                icon: Icon(Icons.calendar_today, size: 16, color: context.gold),
                label: Text(
                  '${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}',
                  style: GoogleFonts.inter(color: context.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.line),
                ),
              ),
              const SizedBox(height: 16),

              InkLedgerCategorySelector(
                categoryType: isIncome ? CategoryType.income : CategoryType.expense,
                selectedCategoryId: _selectedCategoryId,
                selectedSubCategoryName: null,
                label: isIncome ? 'INCOME CATEGORY' : 'EXPENSE CATEGORY',
                onCategorySelected: (catId, subCat) {
                  setState(() {
                    _selectedCategoryId = catId;
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(isIncome ? 'Deposit Account' : 'Payment Account'),
              DropdownButtonFormField<String>(
                initialValue: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                dropdownColor: context.cardBg,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Select Account',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
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
                        Text(acc.name, style: TextStyle(color: context.textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  HapticsService.lightImpact();
                  _save();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isNew ? 'Create Rule' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (!isNew) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    HapticsService.lightImpact();
                    _delete();
                  },
                  style: TextButton.styleFrom(foregroundColor: context.brick),
                  child: const Text('Stop Tracking & Delete'),
                ),
              ],
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
          color: context.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
