import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';

/// Elevated Ink & Ledger Category Selector Button and 2-Step Modal Picker.
class InkLedgerCategorySelector extends StatelessWidget {
  final CategoryType categoryType;
  final String? selectedCategoryId;
  final String? selectedSubCategoryName;
  final void Function(String categoryId, String? subCategoryName) onCategorySelected;
  final String? label;

  const InkLedgerCategorySelector({
    super.key,
    required this.categoryType,
    required this.selectedCategoryId,
    required this.selectedSubCategoryName,
    required this.onCategorySelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories
        .where((c) => c.type == categoryType && (categoryType != CategoryType.income || (c.id != 'other_income' && c.id != 'other' && c.name.toLowerCase() != 'other income')))
        .toList();

    Category? selectedCategory;
    if (selectedCategoryId != null) {
      selectedCategory = categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    }

    final isIncome = categoryType == CategoryType.income;
    final defaultLabel = isIncome ? 'CATEGORY (INCOME)' : 'CATEGORY (EXPENSE)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
          child: Text(
            label ?? defaultLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: context.textMuted,
            ),
          ),
        ),
        InkWell(
          onTap: () => _openCategoryPicker(context, categories),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.line),
            ),
            child: Row(
              children: [
                Icon(
                  selectedCategory?.icon ?? (isIncome ? Icons.account_balance_wallet_outlined : Icons.label_outline_rounded),
                  size: 20,
                  color: selectedCategory != null ? context.gold : context.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selectedCategory == null
                      ? Text(
                          isIncome ? 'Select Income Category' : 'Select Expense Category',
                          style: GoogleFonts.inter(fontSize: 14, color: context.textMuted),
                        )
                      : Row(
                          children: [
                            Text(
                              selectedCategory.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            if (selectedSubCategoryName != null && selectedSubCategoryName!.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Text(
                                  '•',
                                  style: GoogleFonts.inter(color: context.textMuted, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  selectedSubCategoryName!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: context.gold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: context.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openCategoryPicker(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _InkLedgerCategoryPickerSheet(
        categoryType: categoryType,
        categories: categories,
        initialCategoryId: selectedCategoryId,
        initialSubCategory: selectedSubCategoryName,
        onSelected: (catId, subCat) {
          onCategorySelected(catId, subCat);
        },
      ),
    );
  }
}

class _InkLedgerCategoryPickerSheet extends StatefulWidget {
  final CategoryType categoryType;
  final List<Category> categories;
  final String? initialCategoryId;
  final String? initialSubCategory;
  final void Function(String categoryId, String? subCategory) onSelected;

  const _InkLedgerCategoryPickerSheet({
    required this.categoryType,
    required this.categories,
    required this.initialCategoryId,
    required this.initialSubCategory,
    required this.onSelected,
  });

  @override
  State<_InkLedgerCategoryPickerSheet> createState() => _InkLedgerCategoryPickerSheetState();
}

class _InkLedgerCategoryPickerSheetState extends State<_InkLedgerCategoryPickerSheet> {
  Category? _selectedCategory;
  bool _inSubCategoryView = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _selectedCategory = widget.categories.where((c) => c.id == widget.initialCategoryId).firstOrNull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.categoryType == CategoryType.income;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.line),
      ),
      child: SafeArea(
        top: false,
        child: _inSubCategoryView && _selectedCategory != null
            ? _buildSubCategoryView(context, _selectedCategory!)
            : _buildCategoryListView(context, isIncome),
      ),
    );
  }

  Widget _buildCategoryListView(BuildContext context, bool isIncome) {
    final titleKicker = isIncome ? 'INCOME CATEGORY' : 'EXPENSE CATEGORY';
    final titleText = 'Choose a category';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Drag Handle & Close Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKicker,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: context.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titleText,
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: context.textMuted),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.line),

        // Categories List
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: widget.categories.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 64, color: context.line),
            itemBuilder: (context, idx) {
              final cat = widget.categories[idx];
              final isSelected = widget.initialCategoryId == cat.id;

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? context.gold.withValues(alpha: 0.15) : context.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      cat.icon,
                      color: isSelected ? context.gold : context.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                title: Text(
                  cat.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? context.gold : context.textPrimary,
                  ),
                ),
                subtitle: Text(
                  cat.subCategories.isNotEmpty
                      ? '${cat.subCategories.length} subcategories'
                      : (isIncome ? 'Direct category' : 'Top-level category'),
                  style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                ),
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: context.textMuted),
                onTap: () {
                  if (cat.subCategories.isNotEmpty) {
                    setState(() {
                      _selectedCategory = cat;
                      _inSubCategoryView = true;
                    });
                  } else {
                    widget.onSelected(cat.id, null);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),

        if (isIncome)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(Icons.add_rounded, size: 18, color: context.gold),
                label: Text(
                  'Add Custom Income Category',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.gold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.gold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddCustomCategoryDialog(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoryView(BuildContext context, Category category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button and close
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary, size: 20),
                    onPressed: () {
                      setState(() {
                        _inSubCategoryView = false;
                      });
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: context.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a subcategory',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: context.textMuted),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            'Choose a more precise label, keep the parent category, or create a new subcategory.',
            style: GoogleFonts.inter(fontSize: 12, color: context.textMuted, height: 1.3),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: context.line),

        Flexible(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            children: [
              // Top-level parent option
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (widget.initialCategoryId == category.id && widget.initialSubCategory == null)
                        ? context.gold.withValues(alpha: 0.15)
                        : context.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(category.icon, size: 18, color: context.gold),
                  ),
                ),
                title: Text(
                  'Use ${category.name}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.gold,
                  ),
                ),
                subtitle: Text(
                  'Keep this transaction at the top level',
                  style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                ),
                trailing: (widget.initialCategoryId == category.id && (widget.initialSubCategory == null || widget.initialSubCategory!.isEmpty))
                    ? Icon(Icons.check_circle_rounded, color: context.gold, size: 20)
                    : null,
                onTap: () {
                  widget.onSelected(category.id, null);
                  Navigator.pop(context);
                },
              ),
              Divider(height: 1, indent: 64, color: context.line),

              // Subcategories
              ...category.subCategories.map((sub) {
                final isSelected = widget.initialCategoryId == category.id && widget.initialSubCategory == sub.name;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? context.gold.withValues(alpha: 0.15) : context.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        sub.icon,
                        size: 18,
                        color: isSelected ? context.gold : context.textPrimary,
                      ),
                    ),
                  ),
                  title: Text(
                    sub.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? context.gold : context.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Under ${category.name}',
                    style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle_rounded, color: context.gold, size: 20) : null,
                  onTap: () {
                    widget.onSelected(category.id, sub.name);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),

        // Create custom subcategory bottom button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: Icon(Icons.add_rounded, size: 18, color: context.gold),
              label: Text(
                'Create subcategory under ${category.name}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: context.gold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.gold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showAddCustomSubCategoryDialog(context, category),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCustomSubCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: dialogCtx.line),
        ),
        title: Text(
          'New Subcategory',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: dialogCtx.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a subcategory under ${category.name}:',
              style: GoogleFonts.inter(fontSize: 12, color: dialogCtx.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.inter(color: dialogCtx.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Organic Produce, Gym Membership',
                hintStyle: GoogleFonts.inter(color: dialogCtx.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: dialogCtx.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogCtx.isDark ? AppTheme.goldSoft : AppTheme.ink,
              foregroundColor: dialogCtx.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft,
            ),
            onPressed: () async {
              final newSubName = nameController.text.trim();
              if (newSubName.isNotEmpty) {
                final newSub = SubCategory(name: newSubName, icon: Icons.label_outline_rounded);
                final updatedCategory = Category(
                  id: category.id,
                  name: category.name,
                  type: category.type,
                  icon: category.icon,
                  subCategories: [...category.subCategories, newSub],
                );
                await context.read<CategoryProvider>().update(updatedCategory);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                widget.onSelected(category.id, newSubName);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: dialogCtx.line),
        ),
        title: Text(
          'New Income Category',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: dialogCtx.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: GoogleFonts.inter(color: dialogCtx.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Royalties, Stipend',
            hintStyle: GoogleFonts.inter(color: dialogCtx.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: dialogCtx.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogCtx.isDark ? AppTheme.goldSoft : AppTheme.ink,
              foregroundColor: dialogCtx.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft,
            ),
            onPressed: () async {
              final newCatName = nameController.text.trim();
              if (newCatName.isNotEmpty) {
                final newCat = Category(
                  id: 'income_${DateTime.now().millisecondsSinceEpoch}',
                  name: newCatName,
                  type: CategoryType.income,
                  icon: Icons.monetization_on_outlined,
                  subCategories: const [],
                );
                await context.read<CategoryProvider>().add(newCat);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                widget.onSelected(newCat.id, null);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create & Select'),
          ),
        ],
      ),
    );
  }
}
