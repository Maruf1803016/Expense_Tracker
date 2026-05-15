import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';

class AddExpensePage extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpensePage({super.key, this.expenseToEdit});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  CategoryType _selectedType = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expenseToEdit?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.expenseToEdit?.note ?? '',
    );
    _selectedCategoryId = widget.expenseToEdit?.categoryId;
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
    _selectedType = widget.expenseToEdit?.type ?? CategoryType.expense;
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

  void _saveExpense() {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final expense = Expense(
      id: widget.expenseToEdit?.id ?? const Uuid().v4(),
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text,
      type: _selectedType,
    );

    final provider = context.read<ExpenseProvider>();
    if (widget.expenseToEdit != null) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseProvider>().categories;
    final filteredCategories = categories.where((Category c) => c.type == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseToEdit != null ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: CategoryType.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = null; // Reset category when type changes
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  prefixText: '${context.watch<SettingsProvider>().currentSymbol} ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: filteredCategories.map<DropdownMenuItem<String>>((Category c) {
                  final isSub = c.parentId != null;
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        if (isSub) const SizedBox(width: 20),
                        Icon(IconUtils.getIcon(c.icon), size: 18, color: _selectedType == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor),
                        const SizedBox(width: 12),
                        Text(c.name, style: TextStyle(fontSize: isSub ? 14 : 16)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Date'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text(widget.expenseToEdit != null ? 'Update Expense' : 'Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
