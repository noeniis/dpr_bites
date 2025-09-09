class TransactionDetailResult {
  final bool success;
  final Map<String, dynamic> tx; // normalized transaction map
  final List<Map<String, dynamic>> items;

  TransactionDetailResult({
    required this.success,
    required this.tx,
    required this.items,
  });
}

class GenericBoolResult {
  final bool success;
  final String? message;
  GenericBoolResult({required this.success, this.message});
}
