import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    
    // 1. Identify all expenses belonging to this category
    final allExpenses = provider.expenses.where((e) {
      return e.categoryId == widget.category.id;
    }).toList();

    allExpenses.sort((a, b) => b.date.compareTo(a.date));

    // 2. Group expenses by sub-category
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var e in allExpenses) {
      final subKey = e.subCategory ?? 'General';
      if (!groupedExpenses.containsKey(subKey)) {
        groupedExpenses[subKey] = [];
      }
      groupedExpenses[subKey]!.add(e);
    }

    final totalAmount = allExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final color = widget.category.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                      IconUtils.getIcon(widget.category.icon ?? 'category'),
                      size: 40,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total ${widget.category.type.name.toUpperCase()}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w500, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),

            if (allExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: EmptyState(
                  title: 'No Transactions',
                  message: 'Transactions in this category will appear here.',
                  icon: Icons.history,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedExpenses.entries.map((entry) {
                    final isGeneral = entry.key == 'General';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                          child: Row(
                            children: [
                              Icon(
                                isGeneral ? Icons.category : Icons.label_outline,
                                size: 16,
                                color: isGeneral ? Colors.white38 : const Color(0xFF00C896),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isGeneral ? 12 : 13,
                                  fontWeight: isGeneral ? FontWeight.bold : FontWeight.w500,
                                  fontStyle: isGeneral ? FontStyle.normal : FontStyle.italic,
                                  color: isGeneral ? Colors.white38 : const Color(0xFF00C896),
                                  letterSpacing: 1.2,
                                ),
                               ),
                            ],
                          ),
                        ),
                        ...entry.value.map((expense) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: isGeneral ? null : const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFF00C896), width: 3),
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: isGeneral ? null : const Color(0xFF1A2C42),
                              child: ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isGeneral ? 16 : 40,
                                  right: 16,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    IconUtils.getIcon(expense.subCategoryIcon ?? widget.category.icon ?? 'category'), 
                                    color: color, 
                                    size: 18
                                  ),
                                ),
                                title: Text(
                                  expense.title.isEmpty ? widget.category.name : expense.title,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(DateFormatter.format(expense.date), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                                trailing: Text(
                                  CurrencyFormatter.format(expense.amount),
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExpenseDetailPage(expense: expense),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
