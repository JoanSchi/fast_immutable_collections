import 'package:fast_immutable_collections/src/ilist/unmodifiable_list_view.dart';
import 'package:meta/meta.dart';

import '../immutable_collection.dart';
import 'l_add.dart';
import 'l_add_all.dart';
import 'l_flat.dart';
import 'modifiable_list_view.dart';

extension IListExtension<T> on List<T> {
  //
  /// Locks the list, returning an *immutable* list ([IList]).
  IList<T> get lock => IList<T>(this);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////

/// An *immutable* list.
@immutable
class IList<T> // ignore: must_be_immutable
    extends ImmutableCollection<IList<T>> implements Iterable<T> {
  //

  L<T> _l;

  /// If `false`, the equals operator (`==`) compares by identity.
  /// If `true` (the default), the equals operator (`==`) compares all items, ordered.
  final bool isDeepEquals;

  bool get isIdentityEquals => !isDeepEquals;

  static IList<T> empty<T>() => IList._unsafe(LFlat.empty<T>(), isDeepEquals: defaultIsDeepEquals);

  factory IList([
    Iterable<T> iterable,
  ]) =>
      iterable is IList<T>
          ? iterable
          : iterable == null || iterable.isEmpty
              ? IList.empty<T>()
              : IList<T>._unsafe(LFlat<T>(iterable), isDeepEquals: defaultIsDeepEquals);

  /// Unsafe constructor. Use this at your own peril.
  /// This constructor is fast, since it makes no defensive copies of the list.
  /// However, you should only use this with a new list you've created yourself,
  /// when you are sure no external copies exist. If the original list is modified,
  /// it will break the IList and any other derived lists.
  IList.unsafe(List<T> list, {@required this.isDeepEquals})
      : _l = (list == null) ? LFlat.empty<T>() : LFlat<T>.unsafe(list);

  /// Fast if the iterable is an IList.
  IList._(Iterable<T> iterable, {@required this.isDeepEquals})
      : _l = iterable is IList<T>
            ? iterable._l
            : iterable == null
                ? LFlat.empty<T>()
                : LFlat<T>(iterable);

  /// Unsafe.
  IList._unsafe(this._l, {@required this.isDeepEquals});

  IList<T> config({
    bool isDeepEquals,
  }) =>
      IList._unsafe(
        _l,
        isDeepEquals: isDeepEquals ?? this.isDeepEquals,
      );

  /// Converts `this` list to `identityEquals` (compares by `identity`).
  IList<T> get identityEquals => isDeepEquals ? IList._unsafe(_l, isDeepEquals: false) : this;

  /// Convert `this` list to `deepEquals` (compares all list items).
  IList<T> get deepEquals => isDeepEquals ? this : IList._unsafe(_l, isDeepEquals: true);

  /// Unlocks the list, returning a regular (mutable) [List].
  /// This list is "safe", in the sense that is independent from the original [IList].
  List<T> get unlock => List.of(_l);

  /// Unlocks the list, returning a safe, unmodifiable (immutable) [List] view.
  /// The word "view" means the list is backed by the original [IList].
  /// Using this is very fast, since it makes no copies of the [IList] items.
  /// However, if you try to use methods that modify the list, like [add],
  /// it will throw an [UnsupportedError].
  /// It is also very fast to lock this list back into an [IList].
  List<T> get unlockView => UnmodifiableListView(this);

  /// Unlocks the list, returning a safe, modifiable (mutable) [List].
  /// Using this is very fast at first, since it makes no copies of the [IList]
  /// items. However, if and only if you use a method that mutates the list,
  /// like [add], it will unlock internally (make a copy of all IList items). This is
  /// transparent to you, and will happen at most only once. In other words,
  /// it will unlock the IList, lazily, only if necessary.
  /// If you never mutate the list, it will be very fast to lock this list
  /// back into an [IList].
  List<T> get unlockLazy => ModifiableListView(this);

  @override
  Iterator<T> get iterator => _l.iterator;

  @override
  bool get isEmpty => _l.isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  /// If [isDeepEquals] configuration is true:
  /// Will return true only if the list items are equal (and in the same order),
  /// and the list configurations are the same instance. This may be slow for very
  /// large lists, since it compares each item, one by one.
  ///
  /// If [isDeepEquals] configuration is false:
  /// Will return true only if the lists internals are the same instances
  /// (comparing by identity). This will be fast even for very large lists,
  /// since it doesn't compare each item.
  /// Note: This is not the same as `identical(list1, list2)` since it doesn't
  /// compare the lists themselves, but their internal state. Comparing the
  /// internal state is better, because it will return true more often.
  ///
  @override
  bool operator ==(Object other) => (other is IList<T>)
      ? isDeepEquals
          ? equals(other)
          : same(other)
      : false;

  /// Will return true only if the list items are equal (and in the same order),
  /// and the list configurations are the same instance. This may be slow for very
  /// large lists, since it compares each item, one by one.
  @override
  bool equals(IList<T> other) =>
      identical(this, other) ||
      other is IList<T> &&
          runtimeType == other.runtimeType &&
          isDeepEquals == other.isDeepEquals &&
          (flush._l as LFlat<T>).deepListEquals(other.flush._l as LFlat<T>);

  /// Will return true only if the lists internals are the same instances
  /// (comparing by identity). This will be fast even for very large lists,
  /// since it doesn't compare each item.
  /// Note: This is not the same as `identical(list1, list2)` since it doesn't
  /// compare the lists themselves, but their internal state. Comparing the
  /// internal state is better, because it will return true more often.
  @override
  bool same(IList<T> other) => identical(_l, other._l) && (isDeepEquals == other.isDeepEquals);

  @override
  int get hashCode => isDeepEquals //
      ? (flush._l as LFlat<T>).deepListHashcode()
      : identityHashCode(_l);

  /// Compacts the list. Chainable method.
  IList get flush {
    if (!isFlushed) _l = LFlat<T>(_l);
    return this;
  }

  bool get isFlushed => _l is LFlat;

  IList<T> add(T item) => IList<T>._unsafe(_l.add(item), isDeepEquals: isDeepEquals);

  IList<T> addAll(Iterable<T> items) =>
      IList<T>._unsafe(_l.addAll(items), isDeepEquals: isDeepEquals);

  IList<T> remove(T item) {
    final L<T> result = _l.remove(item);
    return identical(result, _l) ? this : IList<T>._unsafe(result, isDeepEquals: isDeepEquals);
  }

  /// Removes the element, if it exists in the list.
  /// Otherwise, adds it to the list.
  IList<T> toggle(T element) => contains(element) ? remove(element) : add(element);

  T operator [](int index) => _l[index];

  // --- Iterable methods: ---------------

  @override
  bool any(bool Function(T) test) => _l.any(test);

  @override
  IList<R> cast<R>() {
    var result = _l.cast<R>();
    return (result is L<R>)
        ? IList._unsafe(result, isDeepEquals: isDeepEquals)
        : IList._(result, isDeepEquals: isDeepEquals);
  }

  @override
  bool contains(Object element) => _l.contains(element);

  @override
  T elementAt(int index) => _l[index];

  @override
  bool every(bool Function(T) test) => _l.every(test);

  @override
  IList<E> expand<E>(Iterable<E> Function(T) f) =>
      IList._(_l.expand(f), isDeepEquals: isDeepEquals);

  @override
  int get length {
    final int length = _l.length;
    if (length == 0 && _l is! LFlat) _l = LFlat.empty<T>();
    return length;
  }

  @override
  T get first => _l.first;

  @override
  T get last => _l.last;

  @override
  T get single => _l.single;

  @override
  T firstWhere(bool Function(T) test, {T Function() orElse}) => _l.firstWhere(test, orElse: orElse);

  @override
  E fold<E>(E initialValue, E Function(E previousValue, T element) combine) =>
      _l.fold(initialValue, combine);

  @override
  IList<T> followedBy(Iterable<T> other) =>
      IList._(_l.followedBy(other), isDeepEquals: isDeepEquals);

  @override
  void forEach(void Function(T element) f) => _l.forEach(f);

  @override
  String join([String separator = '']) => _l.join(separator);

  @override
  T lastWhere(bool Function(T element) test, {T Function() orElse}) =>
      _l.lastWhere(test, orElse: orElse);

  @override
  IList<E> map<E>(E Function(T e) f) => IList._(_l.map(f), isDeepEquals: isDeepEquals);

  @override
  T reduce(T Function(T value, T element) combine) => _l.reduce(combine);

  @override
  T singleWhere(bool Function(T element) test, {T Function() orElse}) =>
      _l.singleWhere(test, orElse: orElse);

  @override
  IList<T> skip(int count) => IList._(_l.skip(count), isDeepEquals: isDeepEquals);

  @override
  IList<T> skipWhile(bool Function(T value) test) =>
      IList._(_l.skipWhile(test), isDeepEquals: isDeepEquals);

  @override
  IList<T> take(int count) => IList._(_l.take(count), isDeepEquals: isDeepEquals);

  @override
  IList<T> takeWhile(bool Function(T value) test) =>
      IList._(_l.takeWhile(test), isDeepEquals: isDeepEquals);

  @override
  IList<T> where(bool Function(T element) test) =>
      IList._(_l.where(test), isDeepEquals: isDeepEquals);

  @override
  IList<E> whereType<E>() => IList._(_l.whereType<E>(), isDeepEquals: isDeepEquals);

  /// If the list has more than `maxLength` elements, it gets cut on
  /// `maxLength`. Otherwise, it removes the last elements so it remains with
  /// only `maxLength` elements.
  IList<T> maxLength(int maxLength) =>
      IList._unsafe(_l.maxLength(maxLength), isDeepEquals: isDeepEquals);

  IList<T> sort([int Function(T a, T b) compare]) =>
      IList._unsafe(_l.sort(compare), isDeepEquals: isDeepEquals);

  @override
  List<T> toList({bool growable = true}) => _l.toList(growable: growable);

  @override
  Set<T> toSet() => _l.toSet();

  @override
  String toString() => "[${_l.join(", ")}]";
}

// /////////////////////////////////////////////////////////////////////////////////////////////////

@visibleForOverriding
abstract class L<T> implements Iterable<T> {
  //

  /// The [L] class provides the default fallback methods of `Iterable`, but
  /// ideally all of its methods are implemented in all of its subclasses.
  /// Note these fallback methods need to calculate the flushed list, but
  /// because that's immutable, we cache it.
  List<T> _flushed;

  List<T> get _getFlushed {
    _flushed ??= unlock;
    return _flushed;
  }

  /// Returns a regular Dart (mutable) List.
  List<T> get unlock => List<T>.of(this);

  @override
  Iterator<T> get iterator;

  L<T> add(T item) {
    return LAdd<T>(this, item);
  }

  L<T> addAll(Iterable<T> items) => LAddAll<T>(
        this,
        (items is IList<T>) ? items._l : items,
      );

  /// TODO: FALTA FAZER!!!
  L<T> remove(T element) => !contains(element) ? this : LFlat<T>.unsafe(unlock..remove(element));

  /// TODO: FALTA FAZER!!!
  /// If the list has more than `maxLength` elements, it gets cut on
  /// `maxLength`. Otherwise, it removes the last elements so it remains with
  /// only `maxLength` elements.
  L<T> maxLength(int maxLength) => maxLength < 0
      ? throw ArgumentError(maxLength)
      : length <= maxLength
          ? this
          : LFlat<T>.unsafe(unlock..length = maxLength);

  L<T> sort([int Function(T a, T b) compare]) => LFlat<T>.unsafe(unlock..sort(compare));

  @override
  bool get isEmpty => _getFlushed.isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  bool any(bool Function(T) test) => _getFlushed.any(test);

  @override
  Iterable<R> cast<R>() => _getFlushed.cast<R>();

  @override
  bool contains(Object element) => _getFlushed.contains(element);

  T operator [](int index) => _getFlushed[index];

  @override
  T elementAt(int index) => _getFlushed[index];

  @override
  bool every(bool Function(T) test) => _getFlushed.every(test);

  @override
  Iterable<E> expand<E>(Iterable<E> Function(T) f) => _getFlushed.expand(f);

  @override
  int get length => _getFlushed.length;

  @override
  T get first => _getFlushed.first;

  @override
  T get last => _getFlushed.last;

  @override
  T get single => _getFlushed.single;

  @override
  T firstWhere(bool Function(T) test, {T Function() orElse}) =>
      _getFlushed.firstWhere(test, orElse: orElse);

  @override
  E fold<E>(E initialValue, E Function(E previousValue, T element) combine) =>
      _getFlushed.fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _getFlushed.followedBy(other);

  @override
  void forEach(void Function(T element) f) => _getFlushed.forEach(f);

  @override
  String join([String separator = '']) => _getFlushed.join(separator);

  @override
  T lastWhere(bool Function(T element) test, {T Function() orElse}) =>
      _getFlushed.lastWhere(test, orElse: orElse);

  @override
  Iterable<E> map<E>(E Function(T e) f) => _getFlushed.map(f);

  @override
  T reduce(T Function(T value, T element) combine) => _getFlushed.reduce(combine);

  @override
  T singleWhere(bool Function(T element) test, {T Function() orElse}) =>
      _getFlushed.singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) => _getFlushed.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _getFlushed.skipWhile(test);

  @override
  Iterable<T> take(int count) => _getFlushed.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _getFlushed.takeWhile(test);

  @override
  Iterable<T> where(bool Function(T element) test) => _getFlushed.where(test);

  @override
  Iterable<E> whereType<E>() => _getFlushed.whereType<E>();

  @override
  List<T> toList({bool growable = true}) => List.of(this, growable: growable);

  @override
  Set<T> toSet() => Set.of(this);
}

// /////////////////////////////////////////////////////////////////////////////////////////////////
