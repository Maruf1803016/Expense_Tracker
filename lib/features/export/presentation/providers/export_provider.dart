import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_tracker/features/export/domain/usecases/get_monthly_export_data.dart';
import 'package:expense_tracker/features/export/data/services/export_service.dart';

enum ExportFormat { csv, pdf }

class ExportProvider with ChangeNotifier {
  final GetMonthlyExportDataUseCase _getExportData;
  final ExportService _exportService;

  ExportProvider({
    required GetMonthlyExportDataUseCase getExportData,
    required ExportService exportService,
  })  : _getExportData = getExportData,
        _exportService = exportService;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// System Hardening: Reset state on logout
  void reset() {
    _isExporting = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Exports data for a single month.
  Future<void> exportMonth({
    required int month,
    required int year,
    required ExportFormat format,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _getExportData(month, year);
      
      final file = format == ExportFormat.csv
          ? await _exportService.generateCSV(data)
          : await _exportService.generatePDF(data);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report - $month/$year',
      );
    } catch (e) {
      _setError('Export failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Exports data for the last 3 months.
  /// Generates separate reports and shares them as a list.
  Future<void> exportLast3Months({
    required DateTime currentMonth,
    required ExportFormat format,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      List<XFile> files = [];
      for (int i = 0; i < 3; i++) {
        final date = DateTime(currentMonth.year, currentMonth.month - i);
        final data = await _getExportData(date.month, date.year);
        final file = format == ExportFormat.csv
            ? await _exportService.generateCSV(data)
            : await _exportService.generatePDF(data);
        files.add(XFile(file.path));
      }

      await Share.shareXFiles(
        files,
        subject: 'Expense Report - Last 3 Months',
      );
    } catch (e) {
      _setError('Multi-month export failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isExporting = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
