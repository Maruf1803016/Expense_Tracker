import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class AccountsManagementPage extends StatelessWidget {
  const AccountsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final accounts = accountProvider.accounts;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Accounts',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 20,
          ),
        ),
      ),
      body: accountProvider.isLoading && accounts.isEmpty
          ? Center(child: CircularProgressIndicator(color: context.gold))
          : accounts.isEmpty
              ? _buildEmptyState(context, accountProvider)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Asset Balance Hero Card (Main Card)
                      Builder(
                        builder: (ctx) {
                          double total = 0.0;
                          for (final a in accounts) {
                            total += Account.calculateBalance(a, expenseProvider.expenses);
                          }
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: ctx.cardBg,
                              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                              border: Border.all(color: ctx.line),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL ASSET LIQUIDITY',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: ctx.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(total),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: ctx.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ctx.surface2,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${accounts.length} Accounts',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ctx.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Dedicated Add an Account Card (Under Main Card)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkLedgerAddCard(
                          title: 'Add an account',
                          subtitle: 'Track bank, mobile money, cash, or credit',
                          icon: Icons.account_balance_wallet_outlined,
                          buttonText: 'Add',
                          onTap: () {
                            HapticsService.selection();
                            _showAddEditAccountSheet(context, accountProvider, null);
                          },
                        ),
                      ),

                      Text(
                        'ACCOUNTS & ASSETS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: accounts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final balance = Account.calculateBalance(account, expenseProvider.expenses);

                          return Container(
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.line),
                            ),
                            child: InkWell(
                              onTap: () {
                                HapticsService.selection();
                                _showAddEditAccountSheet(context, accountProvider, account);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: account.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: IconUtils.buildIcon(
                                          IconUtils.getIconName(account.icon),
                                          color: account.color,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                account.name,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              if (account.isDefault) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: context.gold.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.gold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (account.holderName != null && account.holderName!.isNotEmpty) account.holderName!,
                                              if (account.accountNumber != null && account.accountNumber!.isNotEmpty) Account.getMaskedAccountNumber(account.accountNumber),
                                              account.isDefault ? 'Primary' : 'Secondary',
                                            ].join(' • '),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(balance),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: balance >= 0 ? context.emerald : context.brick,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AccountProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.gold.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_outlined, size: 64, color: context.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Found',
              style: GoogleFonts.fraunces(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create accounts to start tracking your finances across multiple sources.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                HapticsService.selection();
                _showAddEditAccountSheet(context, provider, null);
              },
              child: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  void _showAddEditAccountSheet(BuildContext context, AccountProvider provider, Account? account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditAccountSheet(accountProvider: provider, account: account),
    );
  }
}

class AddEditAccountSheet extends StatefulWidget {
  final AccountProvider accountProvider;
  final Account? account;

  const AddEditAccountSheet({
    super.key,
    required this.accountProvider,
    this.account,
  });

  @override
  State<AddEditAccountSheet> createState() => _AddEditAccountSheetState();
}

class _AddEditAccountSheetState extends State<AddEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String? _selectedIconName;
  Color? _selectedColor;
  bool _isSaving = false;

  bool get isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = widget.account!.name;
      _selectedIconName = IconUtils.getIconName(widget.account!.icon);
      _selectedColor = widget.account!.color;
      _holderNameController.text = widget.account!.holderName ?? '';
      _accountNumberController.text = widget.account!.accountNumber ?? '';
    } else {
      _selectedIconName = IconUtils.availableIconNames.first;
      _selectedColor = AppTheme.categoryPalette.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final isDuplicate = widget.accountProvider.accounts.any(
      (a) => a.name.toLowerCase() == name.toLowerCase() && (!isEdit || a.id != widget.account!.id),
    );

    if (isDuplicate) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.line),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Duplicate Name',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          content: Text(
            'You already have an account named "$name" — are you sure?',
            style: GoogleFonts.inter(color: context.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    final holderNameVal = _holderNameController.text.trim();
    final accountNumberVal = _accountNumberController.text.trim();
    final holderName = holderNameVal.isNotEmpty ? holderNameVal : null;
    final accountNumber = accountNumberVal.isNotEmpty ? accountNumberVal : null;

    try {
      if (isEdit) {
        final updatedAccount = Account(
          id: widget.account!.id,
          name: _nameController.text.trim(),
          icon: IconUtils.getIcon(_selectedIconName),
          color: _selectedColor!,
          initialBalance: widget.account!.initialBalance,
          isDefault: widget.account!.isDefault,
          createdAt: widget.account!.createdAt,
          holderName: holderName,
          accountNumber: accountNumber,
        );
        await widget.accountProvider.update(updatedAccount);
      } else {
        final initialBal = double.tryParse(_balanceController.text.trim()) ?? 0.0;
        final newAccount = Account(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          icon: IconUtils.getIcon(_selectedIconName),
          color: _selectedColor!,
          initialBalance: initialBal,
          isDefault: false,
          createdAt: DateTime.now(),
          holderName: holderName,
          accountNumber: accountNumber,
        );
        await widget.accountProvider.add(newAccount);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.brick),
        );
      }
    }
  }

  void _onDelete() async {
    debugPrint('[AddEditAccountSheet] _onDelete called, accountName=${widget.account?.name}, isDefault=${widget.account?.isDefault}');
    try {
      if (widget.account == null || widget.account!.isDefault) {
        debugPrint('[AddEditAccountSheet] Blocked: null or default account');
        return;
      }

      final defaultAccounts = widget.accountProvider.accounts.where((a) => a.isDefault).toList();
      if (defaultAccounts.isEmpty) {
        debugPrint('[AddEditAccountSheet] Blocked: No default account found to reassign to!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No default account found to reassign transactions to.'), backgroundColor: AppTheme.brick),
          );
        }
        return;
      }
      final defaultAccount = defaultAccounts.first;
      final expenseProvider = context.read<ExpenseProvider>();
      final transactionCount = expenseProvider.expenses
          .where((e) => e.accountId == widget.account!.id && !e.isDeleted)
          .length;

      debugPrint('[AddEditAccountSheet] Showing delete confirmation dialog. Transaction count: $transactionCount');
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.line),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.brick),
          ),
          content: Text(
            transactionCount > 0
                ? '$transactionCount transactions are tagged to this account. Deleting it will move them to ${defaultAccount.name}. This can\'t be undone.'
                : 'Are you sure you want to delete this account? This cannot be undone.',
            style: GoogleFonts.inter(color: context.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.brick,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      debugPrint('[AddEditAccountSheet] Dialog result: $confirm');
      if (confirm == true) {
        setState(() => _isSaving = true);
        debugPrint('[AddEditAccountSheet] Calling accountProvider.delete');
        await widget.accountProvider.delete(widget.account!.id, defaultAccount.id);
        debugPrint('[AddEditAccountSheet] Delete succeeded');
        // Refresh expense list to reflect the reassigned accounts
        await expenseProvider.init(force: true);
        if (mounted) {
          Navigator.pop(context); // Close sheet
        }
      }
    } catch (e, stack) {
      debugPrint('[AddEditAccountSheet] Delete failed with exception: $e\n$stack');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.brick),
        );
      }
    }
  }

  Widget _buildPresetChip({
    required BuildContext context,
    required String label,
    required String iconName,
    required Color color,
  }) {
    return ActionChip(
      avatar: IconUtils.buildIcon(iconName, color: color, size: 14),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: context.textPrimary,
        ),
      ),
      backgroundColor: context.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.line),
      ),
      onPressed: () {
        HapticsService.selection();
        setState(() {
          _nameController.text = label;
          _selectedIconName = iconName;
          _selectedColor = color;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    isEdit ? 'Edit Account' : 'Add Account',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  if (isEdit && !widget.account!.isDefault)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: context.brick),
                      onPressed: _isSaving ? null : _onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick-start presets (Only for Add flow)
              if (!isEdit) ...[
                Text(
                  'Presets',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip(
                        context: context,
                        label: 'Cash',
                        iconName: 'cash',
                        color: AppTheme.categoryPalette[5],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        context: context,
                        label: 'Visa',
                        iconName: 'visa',
                        color: AppTheme.categoryPalette[1],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        context: context,
                        label: 'Mastercard',
                        iconName: 'mastercard',
                        color: AppTheme.categoryPalette[4],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        context: context,
                        label: 'Credit Card',
                        iconName: 'cards',
                        color: AppTheme.categoryPalette[0],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        context: context,
                        label: 'Savings',
                        iconName: 'shield_card',
                        color: AppTheme.categoryPalette[3],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Name
              Text(
                'Account Name',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Savings, Credit Card',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // Starting Balance (Only for Add flow)
              if (!isEdit) ...[
                Text(
                  'Starting Balance (Optional)',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Money already in this account before you started tracking it here.',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _balanceController,
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
                ),
                const SizedBox(height: 20),
              ],

              // Color Picker
              Text(
                'Account Color',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.categoryPalette.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = AppTheme.categoryPalette[index];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        HapticsService.selection();
                        setState(() => _selectedColor = color);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Account Holder Name
              Text(
                'Account Holder Name (Optional)',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _holderNameController,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. John Doe',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
              ),
              const SizedBox(height: 20),

              // Account Number
              Text(
                'Account Number (Optional)',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountNumberController,
                style: GoogleFonts.inter(color: context.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. Last 4 or full 16 digits',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : () {
                  HapticsService.lightImpact();
                  _onSave();
                },
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Add Account',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
