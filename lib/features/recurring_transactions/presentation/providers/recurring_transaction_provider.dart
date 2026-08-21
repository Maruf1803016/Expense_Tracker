import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/recurring_transaction_usecases.dart';

class RecurringTransactionProvider with ChangeNotifier {
  final GetRecurringTransactionSourcesUseCase _getRecurringSources;
  final AddRecurringTransactionSourceUseCase _addRecurringSource;
  final UpdateRecurringTransactionSourceUseCase _updateRecurringSource;
  final DeleteRecurringTransactionSourceUseCase _deleteRecurringSource;
  final MarkRecurringTransactionCompleteUseCase _markComplete;

  List<RecurringTransactionSource> _sources = [];
  List<RecurringTransactionSource> get sources => _sources;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<RecurringTransactionSource>>? _subscription;

  RecurringTransactionProvider({
    required GetRecurringTransactionSourcesUseCase getRecurringSources,
    required AddRecurringTransactionSourceUseCase addRecurringSource,
    required UpdateRecurringTransactionSourceUseCase updateRecurringSource,
    required DeleteRecurringTransactionSourceUseCase deleteRecurringSource,
    required MarkRecurringTransactionCompleteUseCase markComplete,
  })  : _getRecurringSources = getRecurringSources,
        _addRecurringSource = addRecurringSource,
        _updateRecurringSource = updateRecurringSource,
        _deleteRecurringSource = deleteRecurringSource,
        _markComplete = markComplete;

  void init() {
    _subscribe();
  }

  void _subscribe() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _getRecurringSources().listen(
      (data) {
        if (data.isEmpty) {
          final sampleSalary = RecurringTransactionSource(
            id: 'rec_salary',
            name: 'Monthly Salary',
            expectedAmount: 4500.0,
            frequency: 'monthly',
            nextDueDate: DateTime(2026, 8, 30),
            status: 'active',
            type: 'income',
            createdAt: DateTime(2026, 7, 1),
          );
          final sampleRent = RecurringTransactionSource(
            id: 'rec_rent',
            name: 'Apartment Rent',
            expectedAmount: 1850.0,
            frequency: 'monthly',
            nextDueDate: DateTime(2026, 8, 25),
            status: 'active',
            type: 'expense',
            createdAt: DateTime(2026, 7, 1),
          );
          _addRecurringSource(sampleSalary);
          _addRecurringSource(sampleRent);
        }
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

  Future<void> addSource(RecurringTransactionSource source) async {
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

  Future<void> updateSource(RecurringTransactionSource source) async {
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

  Future<void> markAsComplete(RecurringTransactionSource source) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _markComplete(source);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _sources = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
