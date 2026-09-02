import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_data.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class CurrencyPickerSheet extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onCurrencySelected;
  final void Function(String symbol)? onCustomSymbolEntered;

  static List<WorldCurrency> get allCurrencies => kWorldCurrencies;

  const CurrencyPickerSheet({
    super.key,
    required this.selectedCode,
    required this.onCurrencySelected,
    this.onCustomSymbolEntered,
  });

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kWorldCurrencies.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENCY SETTING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: context.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select Global Currency',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
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
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            autofocus: false,
            style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by currency, ISO code, or symbol...',
              hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 16, color: context.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: context.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.line),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
          const SizedBox(height: 12),

          // Currency List with Scrollbar on the right
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.54,
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              thickness: 6,
              radius: const Radius.circular(4),
              child: ListView.separated(
                controller: _scrollController,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: context.line),
                itemBuilder: (context, idx) {
                  final c = filtered[idx];
                  final isSelected = c.code == widget.selectedCode;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    leading: Text(
                      c.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Row(
                      children: [
                        Text(
                          c.code,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? context.gold : context.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isSelected ? context.gold : context.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? context.gold.withValues(alpha: 0.15) : context.surface2,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? context.gold : context.line,
                            ),
                          ),
                          child: Text(
                            c.symbol,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? context.gold : context.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, color: context.gold, size: 18),
                        ],
                      ],
                    ),
                    onTap: () {
                      HapticsService.selection();
                      widget.onCurrencySelected(c.code);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
