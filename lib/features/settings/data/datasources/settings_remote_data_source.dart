import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';

abstract class SettingsRemoteDataSource {
  Future<String> getCurrency();
  Future<void> updateCurrency(String currencyCode);
  Future<double> getBudget();
  Future<void> updateBudget(double budget);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  SettingsRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final uid = authDataSource.currentUserId;
    if (uid == null) throw ServerException('User not authenticated');
    return firestore.collection('users').doc(uid);
  }

  @override
  Future<String> getCurrency() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return 'USD';
    return (doc.data() as Map<String, dynamic>?)?['currency'] as String? ?? 'USD';
  }

  @override
  Future<void> updateCurrency(String currencyCode) async {
    await _userDoc.set({'currency': currencyCode}, SetOptions(merge: true));
  }

  @override
  Future<double> getBudget() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return 0.0;
    return ((doc.data() as Map<String, dynamic>?)?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> updateBudget(double budget) async {
    await _userDoc.set({'monthlyBudget': budget}, SetOptions(merge: true));
  }
}
