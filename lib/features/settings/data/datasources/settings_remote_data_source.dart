import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';

abstract class SettingsRemoteDataSource {
  Future<String> getCurrency();
  Future<void> updateCurrency(String currencyCode);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  SettingsRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  @override
  Future<String> getCurrency() async {
    final uid = authDataSource.currentUserId;
    if (uid == null) throw ServerException('User not authenticated');

    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return 'USD';
    
    return doc.data()?['currency'] as String? ?? 'USD';
  }

  @override
  Future<void> updateCurrency(String currencyCode) async {
    final uid = authDataSource.currentUserId;
    if (uid == null) throw ServerException('User not authenticated');

    await firestore.collection('users').doc(uid).update({
      'currency': currencyCode,
    });
  }
}
