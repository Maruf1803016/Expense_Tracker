/// Standard exception class representing a failure in the Data layer.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'A server error occurred.']);
}

/// Exception class for local storage or cache failures.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'A cache error occurred.']);
}
