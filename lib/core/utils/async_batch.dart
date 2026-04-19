typedef AsyncBatchOperation<T, R> = Future<R> Function(T item);

/// Runs async work in small chunks to improve throughput without blasting the
/// backend with one request per item all at once.
Future<List<R>> runInBatches<T, R>(
  Iterable<T> items, {
  required AsyncBatchOperation<T, R> operation,
  int batchSize = 8,
}) async {
  if (batchSize < 1) {
    throw ArgumentError.value(batchSize, 'batchSize', 'Must be at least 1');
  }

  final source = items.toList(growable: false);
  final results = <R>[];

  for (var start = 0; start < source.length; start += batchSize) {
    final end = start + batchSize > source.length
        ? source.length
        : start + batchSize;
    final batch = source.sublist(start, end);
    results.addAll(await Future.wait(batch.map(operation)));
  }

  return results;
}
