/// Result model for QRIS image download operations.
class QrisDownloadResult {
  final bool success;
  final String? message;
  final String? localPath;
  final String? fileName;
  final int? statusCode;

  const QrisDownloadResult({
    required this.success,
    this.message,
    this.localPath,
    this.fileName,
    this.statusCode,
  });

  factory QrisDownloadResult.success({
    required String localPath,
    required String fileName,
  }) => QrisDownloadResult(
    success: true,
    localPath: localPath,
    fileName: fileName,
  );

  factory QrisDownloadResult.failure(String message, {int? statusCode}) =>
      QrisDownloadResult(
        success: false,
        message: message,
        statusCode: statusCode,
      );

  @override
  String toString() =>
      'QrisDownloadResult(success: ' +
      success.toString() +
      ', localPath: ' +
      (localPath ?? '') +
      ', fileName: ' +
      (fileName ?? '') +
      ', statusCode: ' +
      (statusCode?.toString() ?? 'null') +
      ')';
}
