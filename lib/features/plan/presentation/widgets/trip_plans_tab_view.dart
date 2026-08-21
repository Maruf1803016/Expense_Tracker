import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';

class TripPlansTabView extends StatefulWidget {
  const TripPlansTabView({super.key});

  @override
  State<TripPlansTabView> createState() => _TripPlansTabViewState();
}

class _TripPlansTabViewState extends State<TripPlansTabView> {
  @override
  Widget build(BuildContext context) {
    final tripPlanProvider = context.watch<TripPlanProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    
    final plans = tripPlanProvider.tripPlans;
    final expenses = expenseProvider.expenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: tripPlanProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Column(
              children: [
                if (plans.isNotEmpty) _buildSummaryHeader(plans, expenses),
                Expanded(
                  child: plans.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
                            
                            // spent is sum of expenses
                            final double amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                            final remaining = plan.budgetAmount - amountSpent;
                            final double percentUsed = plan.budgetAmount > 0 ? (amountSpent / plan.budgetAmount) : 0.0;
                            final isOverBudget = remaining < 0;

                            final Color progressColor = isOverBudget ? AppTheme.brick : AppTheme.emerald;
                            final Color remainingColor = isOverBudget ? AppTheme.brick : AppTheme.emerald;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.paperCard,
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                border: Border.all(color: AppTheme.line),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                plan.title,
                                                style: GoogleFonts.fraunces(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.brick, size: 20),
                                              onPressed: () => _showDeletePlanDialog(context, plan),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          plan.endDate != null
                                              ? '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate!)}'
                                              : 'Started ${DateFormatter.format(plan.startDate)}',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: percentUsed.clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: AppTheme.paper2,
                                            color: progressColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Spent: ${CurrencyFormatter.format(amountSpent)} of ${CurrencyFormatter.format(plan.budgetAmount)}',
                                              style: GoogleFonts.inter(
                                                color: AppTheme.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              isOverBudget
                                                  ? 'Over Budget: ${CurrencyFormatter.format(-remaining)}'
                                                  : 'Remaining: ${CurrencyFormatter.format(remaining)}',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: remainingColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddExpensePage(preselectedPlanId: plan.id),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              side: const BorderSide(color: AppTheme.line),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.add_rounded, size: 14, color: AppTheme.gold),
                                            label: Text(
                                              'Add Plan Expense',
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: plans.isEmpty ? null : Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: () => _showAddEditTripPlanSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ink,
            foregroundColor: AppTheme.paper,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
          ),
          child: Text(
            'New Trip Plan',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<TripPlan> plans, List<Expense> expenses) {
    double totalBudget = 0;
    double totalSpent = 0;
    for (var plan in plans) {
      totalBudget += plan.budgetAmount;
      final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
      totalSpent += planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.paperCard,
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE TRIP PLANS BUDGET',
            style: GoogleFonts.inter(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budgeted',
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalBudget),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.line),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalSpent),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brick,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.paper2,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_travel_rounded,
                color: AppTheme.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Trip Plans Yet',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a trip budget upfront and link expenses to track Cox\'s Bazar, Weekend getaway, or Tour budgets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showAddEditTripPlanSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ink,
                foregroundColor: AppTheme.paper,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
              ),
              child: const Text('Add Your First Plan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePlanDialog(BuildContext context, TripPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        title: Text('Remove Trip Plan?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text('Remove plan "${plan.title}"?\n\nAll transactions linked to this plan will remain untouched in your ledger.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TripPlanProvider>().delete(plan.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brick, foregroundColor: Colors.white),
            child: const Text('Remove Plan & Retain Transactions'),
          ),
        ],
      ),
    );
  }

  void _showAddEditTripPlanSheet(BuildContext context, {TripPlan? planToEdit}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: planToEdit?.title ?? '');
    final budgetController = TextEditingController(
      text: planToEdit != null ? planToEdit.budgetAmount.toStringAsFixed(2) : '',
    );
    DateTime startDate = planToEdit?.startDate ?? DateTime.now();
    DateTime? endDate = planToEdit?.endDate;
    String? selectedCategoryId = planToEdit?.categoryId;

    final categories = context.read<CategoryProvider>().categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        planToEdit == null ? 'Create Trip Plan' : 'Edit Trip Plan',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PLAN TITLE',
                        style: GoogleFonts.inter(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        style: GoogleFonts.inter(color: AppTheme.textDark),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Cox\'s Bazar Tour',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BUDGET LIMIT',
                        style: GoogleFonts.inter(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: budgetController,
                        style: GoogleFonts.inter(color: AppTheme.textDark),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 500.00',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'CATEGORY LINK (OPTIONAL)',
                        style: GoogleFonts.inter(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppTheme.paperCard,
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None (General)'),
                          ),
                          ...categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedCategoryId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START DATE',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: startDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) {
                                      setModalState(() {
                                        startDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.line),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormatter.format(startDate),
                                      style: GoogleFonts.inter(color: AppTheme.textDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'END DATE (OPTIONAL)',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: endDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    setModalState(() {
                                      endDate = date;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.line),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          endDate != null ? DateFormatter.format(endDate!) : 'None',
                                          style: GoogleFonts.inter(color: AppTheme.textDark),
                                        ),
                                        if (endDate != null)
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                endDate = null;
                                              });
                                            },
                                            child: const Icon(Icons.clear, size: 16, color: AppTheme.brick),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newPlan = TripPlan(
                                id: planToEdit?.id ?? const Uuid().v4(),
                                title: titleController.text.trim(),
                                budgetAmount: double.parse(budgetController.text.trim()),
                                categoryId: selectedCategoryId,
                                startDate: startDate,
                                endDate: endDate,
                                createdAt: planToEdit?.createdAt ?? DateTime.now(),
                              );

                              final provider = context.read<TripPlanProvider>();
                              if (planToEdit == null) {
                                await provider.add(newPlan);
                              } else {
                                await provider.update(newPlan);
                              }
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            ),
                          ),
                          child: Text(
                            planToEdit == null ? 'Save Plan' : 'Save Changes',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
