import 'package:expense_tracker/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> getCurrency() {
    return remoteDataSource.getCurrency();
  }

  @override
  Future<void> updateCurrency(String currencyCode) {
    return remoteDataSource.updateCurrency(currencyCode);
  }

  @override
  Future<double> getBudget() {
    return remoteDataSource.getBudget();
  }

  @override
  Future<void> updateBudget(double budget) {
    return remoteDataSource.updateBudget(budget);
  }
}
