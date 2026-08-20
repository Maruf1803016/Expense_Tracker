import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

class CurrencyItem {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const CurrencyItem({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

class CurrencyPickerSheet extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onCurrencySelected;

  const CurrencyPickerSheet({
    super.key,
    required this.selectedCode,
    required this.onCurrencySelected,
  });

  static const List<CurrencyItem> allCurrencies = [
    CurrencyItem(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    CurrencyItem(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    CurrencyItem(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    CurrencyItem(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', flag: '🇧🇩'),
    CurrencyItem(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    CurrencyItem(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$', flag: '🇨🇦'),
    CurrencyItem(code: 'AUD', name: 'Australian Dollar', symbol: 'AU\$', flag: '🇦🇺'),
    CurrencyItem(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    CurrencyItem(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦'),
    CurrencyItem(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    CurrencyItem(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭'),
    CurrencyItem(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    CurrencyItem(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
    CurrencyItem(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾'),
    CurrencyItem(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', flag: '🇵🇰'),
    CurrencyItem(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
    CurrencyItem(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    CurrencyItem(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    CurrencyItem(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷'),
    CurrencyItem(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
  ];

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = CurrencyPickerSheet.allCurrencies.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.contains(q);
    }).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Currency',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search currency or country...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
          const SizedBox(height: 16),

          // Currency List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.line),
              itemBuilder: (context, idx) {
                final c = filtered[idx];
                final isSelected = c.code == widget.selectedCode;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Text(
                    c.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Row(
                    children: [
                      Text(
                        c.code,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: GoogleFonts.inter(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.symbol,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.gold : AppTheme.textDark,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, color: AppTheme.gold, size: 20),
                      ],
                    ],
                  ),
                  onTap: () {
                    widget.onCurrencySelected(c.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
