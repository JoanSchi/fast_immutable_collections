// ignore_for_file: overridden_fields
import "dart:math";

import "package:built_collection/built_collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fast_immutable_collections_benchmarks/fast_immutable_collections_benchmarks.dart";
import "package:kt_dart/kt.dart";



class ListAddBenchmark extends MultiBenchmarkReporter<ListBenchmarkBase> {
  @override
  final List<ListBenchmarkBase> benchmarks;

  ListAddBenchmark({required TableScoreEmitter emitter})
      : benchmarks = <ListBenchmarkBase>[
          MutableListAddBenchmark(emitter: emitter),
          IListAddBenchmark(emitter: emitter),
          KtListAddBenchmark(emitter: emitter),
          BuiltListAddWithRebuildBenchmark(emitter: emitter),
          BuiltListAddWithListBuilderBenchmark(emitter: emitter),
        ],
        super(emitter: emitter);
}



class MutableListAddBenchmark extends ListBenchmarkBase {
  MutableListAddBenchmark({required TableScoreEmitter emitter})
      : super(name: "List (Mutable)", emitter: emitter);

  late List<int> list;

  // Saves many copies of the initial list (created during setup).
  late List<List<int>> initialLists;

  late int count;

  @override
  List<int> toMutable() => list;

  /// Since List is mutable, we have to create many copied of the original list during setup.
  /// Note the setup does not count for the measurements.
  @override
  void setup() {
    count = 0;
    initialLists = [];
    for (int i = 0; i <= max(1, 1000000 ~/ config.size); i++)
      initialLists.add(ListBenchmarkBase.getDummyGeneratedList(size: config.size));
  }

  @override
  void run() {
    list = getNextList();
    final _innerRuns = innerRuns();
    for (int i = 0; i < _innerRuns; i++) list.add(i);
  }

  List<int> getNextList() {
    if (count >= initialLists.length - 1)
      count = 0;
    else
      count++;
    return initialLists[count];
  }
}



class IListAddBenchmark extends ListBenchmarkBase {
  IListAddBenchmark({required TableScoreEmitter emitter}) : super(name: "IList", emitter: emitter);

  late IList<int> iList;
  late IList<int> result;

  @override
  List<int> toMutable() => result.unlock;

  @override
  void setup() {
    iList = IList<int>();
    for (int i = 0; i < config.size; i++) iList = iList.add(i);
  }

  @override
  void run() {
    result = iList;
    final _innerRuns = innerRuns();
    for (int i = 0; i < _innerRuns; i++) result = result.add(i);
  }
}



class KtListAddBenchmark extends ListBenchmarkBase {
  KtListAddBenchmark({required TableScoreEmitter emitter})
      : super(name: "KtList", emitter: emitter);

  late KtList<int> ktList;
  late KtList<int> result;

  @override
  List<int> toMutable() => result.asList();

  @override
  void setup() =>
      ktList = ListBenchmarkBase.getDummyGeneratedList(size: config.size).toImmutableList();

  @override
  void run() {
    result = ktList;
    final _innerRuns = innerRuns();
    for (int i = 0; i < _innerRuns; i++) result = result.plusElement(i);
  }
}



class BuiltListAddWithRebuildBenchmark extends ListBenchmarkBase {
  BuiltListAddWithRebuildBenchmark({required TableScoreEmitter emitter})
      : super(name: "BuiltList (Rebuild)", emitter: emitter);

  late BuiltList<int> builtList;
  late BuiltList<int> result;

  @override
  List<int> toMutable() => result.asList();

  @override
  void setup() =>
      builtList = BuiltList<int>(ListBenchmarkBase.getDummyGeneratedList(size: config.size));

  @override
  void run() {
    result = builtList;
    final _innerRuns = innerRuns();
    for (int i = 0; i < _innerRuns; i++)
      result = result.rebuild((ListBuilder<int> listBuilder) => listBuilder.add(i));
  }
}



class BuiltListAddWithListBuilderBenchmark extends ListBenchmarkBase {
  BuiltListAddWithListBuilderBenchmark({required TableScoreEmitter emitter})
      : super(name: "BuiltList (ListBuilder)", emitter: emitter);

  late BuiltList<int> builtList;
  late BuiltList<int> result;

  @override
  List<int> toMutable() => result.asList();

  @override
  void setup() =>
      builtList = BuiltList<int>(ListBenchmarkBase.getDummyGeneratedList(size: config.size));

  @override
  void run() {
    final ListBuilder<int> listBuilder = builtList.toBuilder();
    final _innerRuns = innerRuns();
    for (int i = 0; i < _innerRuns; i++) listBuilder.add(i);
    result = listBuilder.build();
  }
}


