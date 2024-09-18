import 'dart:isolate';
import 'dart:math' show min;

import 'package:flubar/models/cancel_token/cancel_token.dart';
import 'package:flutter/material.dart';

mixin IsolateMixin<T> {
  late CancelToken _token;
  void Function(List<dynamic>)? isolateTask;

  Future<void> performTasks() async {
    _token = CancelToken();
    try {
      await _executeIsolates();
    } catch (e, st) {
      if (e is CancelException) {
        onCancellation(e);
      } else {
        onError(e, st);
        rethrow;
      }
    }
  }

  void cancelTasks([String? reason]) => _token.cancel(reason);

  Future<void> _executeIsolates() async {
    init();
    assert(isolateTask != null);
    final data = getData();
    final dataLength = data.length;
    final receivePort = ReceivePort();
    final chunks = _buildChunks(data);

    var processedCount = 0;
    final futures = chunks.map(
        (chunk) => Isolate.spawn(isolateTask!, [receivePort.sendPort, chunk]));
    final startTimestamp = DateTime.now();
    final isolates = await Future.wait(futures);

    try {
      await for (final message in receivePort.take(dataLength)) {
        if (message is Map<String, dynamic>) {
          processedCount++;
          onProgress(processedCount / dataLength);
          final error = message['error'] as String?;
          if (error != null) {
            final e = message['e'] as Object?;
            final st = message['st'] as StackTrace?;
            onTaskError(error, e, st);
          }
        }
        if (_token.isCancelled) {
          throw CancelException(_token.cancelReason);
        }
      }
    } finally {
      final endTimestamp = DateTime.now();
      onIsolatesCompletion(isolates);
      receivePort.close();
      onCompletion(endTimestamp.difference(startTimestamp));
    }
  }

  Iterable<List<T>> _buildChunks(List<T> data) sync* {
    final dataLength = data.length;
    final isolateCount = min(getIsolateCount(), dataLength);
    final chunkSize = (dataLength / isolateCount).ceil();
    for (var i = 0; i < dataLength; i += chunkSize) {
      final end = min(i + chunkSize, dataLength);
      yield data.sublist(i, end);
    }
  }

  @protected
  List<T> getData();

  @protected
  int getIsolateCount();

  @protected
  void init();

  @protected
  void onCancellation(CancelException e);

  @protected
  void onCompletion(Duration duration);

  @protected
  void onError(Object e, StackTrace st);

  @protected
  void onIsolatesCompletion(List<Isolate> isolates);

  @protected
  void onProgress(double progress);

  @protected
  void onTaskError(String? error, Object? e, StackTrace? st);
}
