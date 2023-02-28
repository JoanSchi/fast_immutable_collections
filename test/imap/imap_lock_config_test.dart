// ignore_for_file: prefer_const_constructors

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:test/test.dart";

void main() {
  /////////////////////////////////////////////////////////////////////////////

  test("lockConfig", () {
    ImmutableCollection.lockConfig();

    expect(() => IMap.flushFactor = 1000, throwsStateError);
    expect(() => IMap.resetAllConfigurations(), throwsStateError);
    expect(() => IMap.defaultConfig = ConfigMap(cacheHashCode: false), throwsStateError);
  });

  /////////////////////////////////////////////////////////////////////////////
}
