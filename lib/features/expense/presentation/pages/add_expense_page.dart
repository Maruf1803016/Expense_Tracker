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

class AddExpensePage extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpensePage({super.key, this.expenseToEdit});

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
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedSubCategoryName;
  String? _selectedSubCategoryIcon;

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
    _selectedCategoryId = widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _selectedType = widget.expenseToEdit?.type ?? CategoryType.expense;
    _selectedSubCategoryName = widget.expenseToEdit?.subCategory;
    _selectedSubCategoryIcon = widget.expenseToEdit?.subCategoryIcon;
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
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    final expense = Expense(
      id: widget.expenseToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text,
      type: _selectedType,
      subCategory: _selectedSubCategoryName,
      subCategoryIcon: _selectedSubCategoryIcon,
    );

    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (widget.expenseToEdit != null) {
      await provider.updateExpense(expense);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_selectedType == CategoryType.expense ? 'Expense' : 'Income'} updated'),
          backgroundColor: AppTheme.emeraldGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await provider.addExpense(expense);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_selectedType == CategoryType.expense ? 'Expense' : 'Income'} saved'),
          backgroundColor: AppTheme.emeraldGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

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
              // Toggle: Expense / Income
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: CategoryType.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = null; 
                    _selectedSubCategoryName = null;
                    _selectedSubCategoryIcon = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Title
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

              // Amount
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

              // Category
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
                    for (var c in categories.where((c) => c.type == _selectedType)) {
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
                            color: _selectedType == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor,
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
              
              // Sub-category (Expense Only)
              if (_selectedType == CategoryType.expense) ...[
                _buildSectionLabel('Sub-category'),
                _buildInputCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildSubCategorySection(context, categories),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Date
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

              // Note
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
                  _selectedType == CategoryType.expense ? 'Save Expense' : 'Save Income',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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

  Widget _buildSubCategorySection(BuildContext context, List<Category> categories) {
    if (_selectedCategoryId == null) {
      return const Text(
        'Please select a category first',
        style: TextStyle(color: Colors.white54, fontSize: 14),
      );
    }

    final category = categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first);
    if (category.subCategories.isEmpty) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 16, color: AppTheme.emeraldGreen),
            label: const Text('Add Custom', style: TextStyle(color: AppTheme.emeraldGreen)),
            onPressed: () => _showAddCustomSubCategoryDialog(context, category),
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ],
      );
    }

    final List<Widget> chips = [];
    for (var sub in category.subCategories) {
      final isSelected = _selectedSubCategoryName == sub.name;
      chips.add(
        ChoiceChip(
          avatar: Icon(sub.icon, size: 16, color: isSelected ? Colors.white : Colors.white54),
          label: Text(sub.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSubCategoryName = sub.name;
                _selectedSubCategoryIcon = IconUtils.getIconName(sub.icon);
              } else {
                _selectedSubCategoryName = null;
                _selectedSubCategoryIcon = null;
              }
            });
          },
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
        onPressed: () => _showAddCustomSubCategoryDialog(context, category),
        backgroundColor: Colors.white.withOpacity(0.05),
      ),
    );

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: chips,
    );
  }

  void _showAddCustomSubCategoryDialog(BuildContext context, Category category) {
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
              _selectedSubCategoryName = name;
              _selectedSubCategoryIcon = IconUtils.getIconName(icon);
            });
          },
        );
      },
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
