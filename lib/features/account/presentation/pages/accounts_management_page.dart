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

class AccountsManagementPage extends StatelessWidget {
  const AccountsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final accounts = accountProvider.accounts;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Accounts',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textDark),
            onPressed: () => _showAddEditAccountSheet(context, accountProvider, null),
          ),
        ],
      ),
      body: accountProvider.isLoading && accounts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : accounts.isEmpty
              ? _buildEmptyState(context, accountProvider)
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final balance = Account.calculateBalance(account, expenseProvider.expenses);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.paperCard,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: InkWell(
                        onTap: () => _showAddEditAccountSheet(context, accountProvider, account),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: account.color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: IconUtils.buildIcon(
                                    IconUtils.getIconName(account.icon),
                                    color: account.color,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                            fontSize: 14,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        if (account.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.gold.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'DEFAULT',
                                              style: GoogleFonts.inter(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      account.isDefault ? 'Primary Account' : 'Custom Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(balance),
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: balance >= 0 ? AppTheme.emerald : AppTheme.brick,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                color: AppTheme.gold.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Found',
              style: GoogleFonts.fraunces(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create accounts to start tracking your finances across multiple sources.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showAddEditAccountSheet(context, provider, null),
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
    } else {
      _selectedIconName = IconUtils.availableIconNames.first;
      _selectedColor = AppTheme.categoryPalette.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

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
    if (widget.account == null || widget.account!.isDefault) return;

    final defaultAccount = widget.accountProvider.accounts.firstWhere((a) => a.isDefault);
    final expenseProvider = context.read<ExpenseProvider>();
    final transactionCount = expenseProvider.expenses
        .where((e) => e.accountId == widget.account!.id && !e.isDeleted)
        .length;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.line),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Text(
          transactionCount > 0
              ? '$transactionCount transactions are tagged to this account. Deleting it will move them to ${defaultAccount.name}. This can\'t be undone.'
              : 'Are you sure you want to delete this account? This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await widget.accountProvider.delete(widget.account!.id, defaultAccount.id);
        // Refresh expense list to reflect the reassigned accounts
        await expenseProvider.init(force: true);
        if (mounted) {
          Navigator.pop(context); // Close sheet
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.brick),
          );
        }
      }
    }
  }

  Widget _buildPresetChip({
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
          color: AppTheme.textDark,
        ),
      ),
      backgroundColor: AppTheme.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.line),
      ),
      onPressed: () {
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
      decoration: const BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (isEdit && !widget.account!.isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.brick),
                      onPressed: _isSaving ? null : _onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick-start presets (Only for Add flow)
              if (!isEdit) ...[
                Text(
                  'Presets',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip(
                        label: 'Cash',
                        iconName: 'cash',
                        color: AppTheme.categoryPalette[5],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        label: 'Visa',
                        iconName: 'visa',
                        color: AppTheme.categoryPalette[1],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        label: 'Mastercard',
                        iconName: 'mastercard',
                        color: AppTheme.categoryPalette[4],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
                        label: 'Credit Card',
                        iconName: 'cards',
                        color: AppTheme.categoryPalette[0],
                      ),
                      const SizedBox(width: 8),
                      _buildPresetChip(
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
                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: AppTheme.textDark),
                decoration: const InputDecoration(
                  hintText: 'e.g. Savings, Credit Card',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // Starting Balance (Only for Add flow)
              if (!isEdit) ...[
                Text(
                  'Starting Balance (Optional)',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Money already in this account before you started tracking it here.',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _balanceController,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Color Picker
              Text(
                'Account Color',
                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold),
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
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: AppTheme.textDark, width: 3)
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

              // Icon Picker
              Text(
                'Account Icon',
                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: IconUtils.availableIconNames.length,
                  itemBuilder: (context, index) {
                    final name = IconUtils.availableIconNames[index];
                    final icon = IconUtils.getIcon(name);
                    final isSelected = _selectedIconName == name;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconName = name),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor!.withOpacity(0.15) : AppTheme.paper,
                          border: Border.all(
                            color: isSelected ? _selectedColor! : AppTheme.line,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: IconUtils.buildIcon(
                            name,
                            color: isSelected ? _selectedColor : AppTheme.textDark,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _onSave,
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
