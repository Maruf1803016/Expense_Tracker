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
  late TextEditingController _subCategoryController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  CategoryType _selectedType = CategoryType.expense;
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
    _subCategoryController = TextEditingController(
      text: widget.expenseToEdit?.subCategory ?? '',
    );
    _selectedCategoryId = widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _selectedType = widget.expenseToEdit?.type ?? CategoryType.expense;
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
      subCategory: _subCategoryController.text.trim().isEmpty ? null : _subCategoryController.text.trim(),
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

  final List<IconData> _subCategoryIcons = [
    Icons.lunch_dining, Icons.local_cafe, Icons.directions_car,
    Icons.shopping_bag, Icons.medication, Icons.home,
    Icons.sports_esports, Icons.school
  ];
  
  final List<String> _subCategoryIconNames = [
    'lunch_dining', 'local_cafe', 'directions_car',
    'shopping_bag', 'medication', 'home',
    'sports', 'school'
  ];

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
                    for (var c in categories.where((c) => c.type == _selectedType && c.parentId == null)) {
                      unique[c.id] = c;
                    }
                    final sorted = unique.values.toList()..sort((a, b) => a.name.compareTo(b.name));
                    return sorted.map((category) => DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(
                            IconUtils.getIcon(category.icon),
                            size: 20,
                            color: _selectedType == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor,
                          ),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    )).toList();
                  }(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),
              
              // Sub-category
              _buildSectionLabel('Sub-category'),
              _buildInputCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _subCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Enter sub-category',
                        prefixIcon: Icon(_selectedSubCategoryIcon != null 
                            ? IconUtils.getIcon(_selectedSubCategoryIcon!) 
                            : Icons.label_outline),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_subCategoryIcons.length, (index) {
                          final icon = _subCategoryIcons[index];
                          final name = _subCategoryIconNames[index];
                          final isSelected = _selectedSubCategoryIcon == name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.white54),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubCategoryIcon = selected ? name : null;
                                });
                              },
                              selectedColor: AppTheme.emeraldGreen,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              showCheckmark: false,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
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
    _subCategoryController.dispose();
    super.dispose();
  }
}
