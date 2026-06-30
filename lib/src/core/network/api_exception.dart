class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.errors});

  final String message;
  final int? code;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}
