Future<List<R>> mapLimited<T, R>(
  Iterable<T> items,
  int concurrency,
  Future<R> Function(T item) mapper,
) async {
  final list = items.toList();
  if (list.isEmpty) return <R>[];
  final limit = concurrency < 1 ? 1 : concurrency;
  final results = List<R?>.filled(list.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final index = nextIndex;
      nextIndex += 1;
      if (index >= list.length) return;
      results[index] = await mapper(list[index]);
    }
  }

  await Future.wait(List<Future<void>>.generate(limit, (_) => worker()));
  return results.cast<R>();
}
