import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart'
    as impl;

part 'local_database.g.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text()();
  TextColumn get content => text()();
  TextColumn get type => text()();
  TextColumn get mediaUrl => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get replyToId => text().nullable()();
  BoolColumn get isForwarded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get partnerId => text().nullable()();
  TextColumn get moodEmoji => text().withDefault(const Constant('🤍'))();
  DateTimeColumn get lastSeen => dateTime().nullable()();
  TextColumn get blockedIds => text().map(const StringListConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalScrapbookItems extends Table {
  TextColumn get id => text()();
  TextColumn get uploaderId => text()();
  TextColumn get coupleId => text()();
  TextColumn get imageUrl => text()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    return value.join(',');
  }
}

@DriftDatabase(tables: [LocalMessages, LocalProfiles, LocalScrapbookItems])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Messages DAO methods
  Future<void> saveMessages(List<LocalMessage> messages) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localMessages, messages);
    });
  }

  Stream<List<LocalMessage>> watchMessages(String userId, String partnerId) {
    return (select(localMessages)
          ..where(
            (t) =>
                (t.senderId.equals(userId) & t.receiverId.equals(partnerId)) |
                (t.senderId.equals(partnerId) & t.receiverId.equals(userId)),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  // Profile DAO methods
  Future<void> saveProfile(LocalProfile profile) async {
    await into(localProfiles).insertOnConflictUpdate(profile);
  }

  Stream<LocalProfile?> watchProfile(String id) {
    return (select(
      localProfiles,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  // Scrapbook DAO methods
  Future<void> saveScrapbookItems(List<LocalScrapbookItem> items) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localScrapbookItems, items);
    });
  }

  Stream<List<LocalScrapbookItem>> watchScrapbookItems(String coupleId) {
    return (select(localScrapbookItems)
          ..where((t) => t.coupleId.equals(coupleId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}

QueryExecutor _openConnection() {
  return impl.openConnection();
}
