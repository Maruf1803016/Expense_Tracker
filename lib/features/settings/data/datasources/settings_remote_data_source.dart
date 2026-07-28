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
    await _userDoc.set({'currency': currencyCode}, SetOptions(merge: true)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw const ServerException(
        'Request timed out. Please check your connection and try again.',
      ),
    );
  }
}
