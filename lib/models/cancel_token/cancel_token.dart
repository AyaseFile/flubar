class CancelToken {
  bool _cancelled = false;
  String? _cancelReason;

  bool get isCancelled => _cancelled;

  String? get cancelReason => _cancelReason;

  void cancel([String? reason]) {
    _cancelled = true;
    _cancelReason = reason;
  }
}

class CancelException implements Exception {
  final String? reason;

  CancelException([this.reason]);

  @override
  String toString() {
    return 'CancelException: $reason';
  }
}
