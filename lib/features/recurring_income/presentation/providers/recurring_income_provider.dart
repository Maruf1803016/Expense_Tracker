import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';
import 'package:expense_tracker/features/recurring_income/domain/usecases/recurring_income_usecases.dart';

class RecurringIncomeProvider with ChangeNotifier {
  final GetRecurringIncomeSourcesUseCase _getRecurringSources;
  final AddRecurringIncomeSourceUseCase _addRecurringSource;
  final UpdateRecurringIncomeSourceUseCase _updateRecurringSource;
  final DeleteRecurringIncomeSourceUseCase _deleteRecurringSource;
  final MarkRecurringIncomeReceivedUseCase _markReceived;

  List<RecurringIncomeSource> _sources = [];
  List<RecurringIncomeSource> get sources => _sources;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<RecurringIncomeSource>>? _subscription;

  RecurringIncomeProvider({
    required GetRecurringIncomeSourcesUseCase getRecurringSources,
    required AddRecurringIncomeSourceUseCase addRecurringSource,
    required UpdateRecurringIncomeSourceUseCase updateRecurringSource,
    required DeleteRecurringIncomeSourceUseCase deleteRecurringSource,
    required MarkRecurringIncomeReceivedUseCase markReceived,
  })  : _getRecurringSources = getRecurringSources,
        _addRecurringSource = addRecurringSource,
        _updateRecurringSource = updateRecurringSource,
        _deleteRecurringSource = deleteRecurringSource,
        _markReceived = markReceived {
    _subscribe();
  }

  void _subscribe() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _getRecurringSources().listen(
      (data) {
        _sources = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  Future<void> addSource(RecurringIncomeSource source) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _addRecurringSource(source);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSource(RecurringIncomeSource source) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _updateRecurringSource(source);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSource(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _deleteRecurringSource(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsReceived(RecurringIncomeSource source) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _markReceived(source);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
