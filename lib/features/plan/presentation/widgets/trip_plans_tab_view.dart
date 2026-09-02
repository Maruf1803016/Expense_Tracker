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
import 'package:expense_tracker/features/plan/presentation/pages/trip_plan_detail_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

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
      body: tripPlanProvider.isLoading && plans.isEmpty
          ? Center(child: CircularProgressIndicator(color: context.gold))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Main Summary Header Card
                _buildSummaryHeader(plans, expenses),

                // 2. Dedicated Add a Trip Plan Card (Under Main Card)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkLedgerAddCard(
                    title: 'Add a trip & event plan',
                    subtitle: 'Set budget for trips, vacations, and special events',
                    icon: Icons.flight_takeoff_rounded,
                    buttonText: 'Add',
                    onTap: () {
                      HapticsService.selection();
                      _showAddEditTripPlanSheet(context);
                    },
                  ),
                ),

                // Section Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
                  child: Text(
                    'TRIP & EVENT PLANS (${plans.length})',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.textMuted,
                    ),
                  ),
                ),

                if (plans.isEmpty)
                  _buildEmptyState(context)
                else
                  ...plans.map((plan) {
                    final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
                    final double amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                    final remaining = plan.budgetAmount - amountSpent;
                    final double percentUsed = plan.budgetAmount > 0 ? (amountSpent / plan.budgetAmount) : 0.0;
                    final isOverBudget = remaining < 0;

                    final Color progressColor = isOverBudget ? context.brick : context.emerald;
                    final Color remainingColor = isOverBudget ? context.brick : context.emerald;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: context.line),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        onTap: () {
                          HapticsService.selection();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripPlanDetailPage(plan: plan),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: context.brick, size: 18),
                                    onPressed: () => _showDeletePlanDialog(context, plan),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.endDate != null
                                    ? '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate!)}'
                                    : 'Started ${DateFormatter.format(plan.startDate)}',
                                style: GoogleFonts.inter(
                                  color: context.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentUsed.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: context.surface2,
                                  color: progressColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${CurrencyFormatter.format(amountSpent)} of ${CurrencyFormatter.format(plan.budgetAmount)}',
                                    style: GoogleFonts.inter(
                                      color: context.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    isOverBudget
                                        ? 'Over: ${CurrencyFormatter.format(-remaining)}'
                                        : 'Remaining: ${CurrencyFormatter.format(remaining)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: remainingColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
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
    final remaining = totalBudget - totalSpent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flight_takeoff_rounded, color: context.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Trip & Event Plans Budget',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${plans.length} Active Plans',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BUDGET',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalBudget),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: context.line),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalSpent),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? context.brick : context.gold,
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
                color: context.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_travel_rounded,
                color: context.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Trip Plans Yet',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a trip budget upfront and link expenses to track Cox\'s Bazar, Weekend getaway, or Tour budgets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: context.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                HapticsService.selection();
                _showAddEditTripPlanSheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.gold,
                foregroundColor: Colors.white,
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
        backgroundColor: context.cardBg,
        title: Text('Remove Trip Plan?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Text(
          'Remove plan "${plan.title}"?\n\nAll transactions linked to this plan will remain untouched in your ledger.',
          style: TextStyle(color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              HapticsService.lightImpact();
              Navigator.pop(context);
              context.read<TripPlanProvider>().delete(plan.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.brick, foregroundColor: Colors.white),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: ctx.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: ctx.line),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                            color: ctx.line,
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
                          color: ctx.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PLAN TITLE',
                        style: GoogleFonts.inter(
                          color: ctx.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        style: GoogleFonts.inter(color: ctx.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Cox\'s Bazar Tour',
                          hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                          filled: true,
                          fillColor: ctx.cardBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BUDGET LIMIT',
                        style: GoogleFonts.inter(
                          color: ctx.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: budgetController,
                        style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 500.00',
                          hintStyle: GoogleFonts.spaceGrotesk(color: ctx.textMuted),
                          filled: true,
                          fillColor: ctx.cardBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
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
                          color: ctx.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: ctx.cardBg,
                        initialValue: selectedCategoryId,
                        style: GoogleFonts.inter(color: ctx.textPrimary),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          filled: true,
                          fillColor: ctx.cardBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('None (General)', style: TextStyle(color: ctx.textPrimary)),
                          ),
                          ...categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name, style: TextStyle(color: ctx.textPrimary)),
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
                                    color: ctx.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: ctx,
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
                                      color: ctx.cardBg,
                                      border: Border.all(color: ctx.line),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormatter.format(startDate),
                                      style: GoogleFonts.inter(color: ctx.textPrimary),
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
                                    color: ctx.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: ctx,
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
                                      color: ctx.cardBg,
                                      border: Border.all(color: ctx.line),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          endDate != null ? DateFormatter.format(endDate!) : 'None',
                                          style: GoogleFonts.inter(color: ctx.textPrimary),
                                        ),
                                        if (endDate != null)
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                endDate = null;
                                              });
                                            },
                                            child: Icon(Icons.clear, size: 16, color: ctx.brick),
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
                            HapticsService.lightImpact();
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
                              
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ctx.gold,
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
