import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';

class PlansTabView extends StatefulWidget {
  const PlansTabView({super.key});

  @override
  State<PlansTabView> createState() => _PlansTabViewState();
}

class _PlansTabViewState extends State<PlansTabView> {
  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final plans = planProvider.plans.where((p) => !p.isArchived).toList();
    final expenses = expenseProvider.expenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: planProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))
          : plans.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    
                    // Computed live spending
                    final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted);
                    final amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                    final remaining = plan.totalBudget - amountSpent;
                    
                    final double percentUsed = plan.totalBudget > 0 ? (amountSpent / plan.totalBudget) : 0.0;
                    
                    Color progressColor;
                    if (percentUsed < 0.8) {
                      progressColor = AppTheme.emeraldGreen;
                    } else if (percentUsed <= 1.0) {
                      progressColor = Colors.amber;
                    } else {
                      progressColor = AppTheme.expenseColor;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      color: AppTheme.secondaryBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.archive_outlined, size: 20, color: Colors.white.withOpacity(0.4)),
                                  onPressed: () async {
                                    final updated = Plan(
                                      id: plan.id,
                                      title: plan.title,
                                      totalBudget: plan.totalBudget,
                                      startDate: plan.startDate,
                                      endDate: plan.endDate,
                                      categoryId: plan.categoryId,
                                      note: plan.note,
                                      createdAt: plan.createdAt,
                                      isArchived: true,
                                    );
                                    await planProvider.update(updated);
                                  },
                                ),
                              ],
                            ),
                            if (plan.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                plan.note,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.4)),
                                const SizedBox(width: 6),
                                Text(
                                  '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Budget',
                                      style: TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(plan.totalBudget),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Spent',
                                      style: TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(amountSpent),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: progressColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Remaining',
                                      style: TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(remaining),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: remaining >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentUsed.clamp(0.0, 1.0),
                                minHeight: 8,
                                color: progressColor,
                                backgroundColor: progressColor.withOpacity(0.1),
                              ),
                            ),
                            if (percentUsed > 1.0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.expenseColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Over budget by ${CurrencyFormatter.format(amountSpent - plan.totalBudget)}',
                                    style: TextStyle(
                                      color: AppTheme.expenseColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanBottomSheet(context),
        backgroundColor: AppTheme.emeraldGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, size: 64, color: AppTheme.emeraldGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Custom Plans Yet',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Set dynamic custom budgets with fixed date ranges and track specific projects or trips.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showAddPlanBottomSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Create First Plan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPlanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePlanSheet(),
    );
  }
}

class _CreatePlanSheet extends StatefulWidget {
  const _CreatePlanSheet();

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Custom Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              // Title
              _buildLabel('Plan Title'),
              _buildInputContainer(
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Summer Vacation / Wedding',
                    prefixIcon: Icon(Icons.title),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              _buildLabel('Total Budget'),
              _buildInputContainer(
                child: TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                    border: InputBorder.none,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Budget is required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Date'),
                        _buildInputContainer(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('End Date'),
                        _buildInputContainer(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Optional Category
              _buildLabel('Limit to Category (Optional)'),
              _buildInputContainer(
                child: DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                    border: InputBorder.none,
                  ),
                  items: () {
                    final List<DropdownMenuItem<String?>> items = [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                    ];
                    items.addAll(categories.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    )));
                    return items;
                  }(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              _buildLabel('Note / Description'),
              _buildInputContainer(
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add description...',
                    prefixIcon: Icon(Icons.notes),
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
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
                onPressed: (_titleController.text.trim().isEmpty ||
                        _budgetController.text.trim().isEmpty ||
                        _isSaving)
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSaving = true);
                        
                        final plan = Plan(
                          id: const Uuid().v4(),
                          title: _titleController.text.trim(),
                          totalBudget: double.parse(_budgetController.text.trim()),
                          startDate: _startDate,
                          endDate: _endDate,
                          categoryId: _selectedCategoryId,
                          note: _noteController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        
                        final navigator = Navigator.of(context);
                        await context.read<PlanProvider>().add(plan);
                        navigator.pop();
                      },
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
