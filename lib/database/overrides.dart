part of 'database.dart';

@DataClassName('RawOverride')
class Overrides extends Table {
  @override
  String get tableName => 'overrides';

  IntColumn get id => integer()();

  TextColumn get label => text()();

  TextColumn get ext => textEnum<OverrideType>()();

  DateTimeColumn get lastUpdateTime => dateTime()();

  BoolColumn get global => boolean().withDefault(const Constant(false))();

  TextColumn get url => text().nullable()();

  IntColumn get order => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Overrides])
class OverridesDao extends DatabaseAccessor<Database> with _$OverridesDaoMixin {
  OverridesDao(super.attachedDatabase);

  Selectable<OverrideItem> query() {
    return overrides.readable(
      (row) => row.toOverride(),
      orderBy: [
        (t) => OrderingTerm(expression: t.order, nulls: NullsOrder.last),
        (t) => OrderingTerm.asc(t.id),
      ],
    );
  }

  Future<void> putAll(Iterable<OverridesCompanion> items) async {
    await batch((b) async {
      b.insertAllOnConflictUpdate(overrides, items);
    });
  }

  Selectable<OverrideItem> get(int overrideId) {
    return overrides.readable(
      (row) => row.toOverride(),
      where: (t) => t.id.equals(overrideId),
    );
  }

  Selectable<int> ids() {
    final query = overrides.selectOnly()..addColumns([overrides.id]);
    return query.map((row) => row.read(overrides.id)!);
  }

  Future<void> setAllWithBatch(
    Batch batch,
    Iterable<OverrideItem> items,
  ) async {
    final List<OverridesCompanion> companions = [];
    final List<int> ids = [];
    for (final item in items) {
      ids.add(item.id);
      companions.add(item.toCompanion());
    }
    overrides.setAll(batch, companions, deleteFilter: (t) => t.id.isNotIn(ids));
  }

  void putAllWithBatch(Batch batch, Iterable<OverrideItem> items) {
    batch.insertAllOnConflictUpdate(
      overrides,
      items.map((item) => item.toCompanion()),
    );
  }
}

extension RawOverrideExt on RawOverride {
  OverrideItem toOverride() {
    return OverrideItem(
      id: id,
      label: label,
      ext: ext,
      lastUpdateTime: lastUpdateTime,
      global: global,
      url: url,
      order: order,
    );
  }
}

extension OverridesCompanionExt on OverrideItem {
  OverridesCompanion toCompanion([int? order]) {
    return OverridesCompanion.insert(
      id: Value(id),
      label: label,
      ext: ext,
      lastUpdateTime: lastUpdateTime,
      global: Value(global),
      url: Value(url),
      order: Value(order ?? this.order),
    );
  }
}
