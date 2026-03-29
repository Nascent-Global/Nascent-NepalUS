import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

part 'app_database.g.dart';

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  @override
  String get tableName => 'user_profile';

  TextColumn get id => text()();

  TextColumn get username => text()();

  TextColumn get avatar => text()();

  TextColumn get timezone => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DailyEntryRow')
class DailyEntries extends Table {
  @override
  String get tableName => 'daily_entries';

  TextColumn get id => text()();

  TextColumn get date => text()();

  RealColumn get sleepHours => real()();

  RealColumn get workHours => real()();

  IntColumn get mood =>
      integer().customConstraint('NOT NULL CHECK (mood BETWEEN 1 AND 5)')();

  IntColumn get exerciseMinutes => integer().withDefault(const Constant(0))();

  BoolColumn get includePomodoroWork =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BurnoutScoreRow')
class BurnoutScores extends Table {
  @override
  String get tableName => 'burnout_scores';

  TextColumn get id => text()();

  TextColumn get date => text()();

  IntColumn get score =>
      integer().customConstraint('NOT NULL CHECK (score BETWEEN 0 AND 100)')();

  TextColumn get classification => text().customConstraint(
    "NOT NULL CHECK (classification IN ('low','medium','high'))",
  )();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BurnoutCauseRow')
class BurnoutCauses extends Table {
  @override
  String get tableName => 'burnout_causes';

  TextColumn get id => text()();

  TextColumn get scoreId =>
      text().references(BurnoutScores, #id, onDelete: KeyAction.cascade)();

  TextColumn get causeType => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();

  TextColumn get date => text()();

  TextColumn get title => text()();

  DateTimeColumn get deadline => dateTime().nullable()();

  IntColumn get priority => integer().withDefault(const Constant(1))();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  TextColumn get taskType => text().customConstraint(
    "NOT NULL CHECK (task_type IN ('user','recovery'))",
  )();

  TextColumn get reason => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ScoreLogRow')
class ScoreLogs extends Table {
  @override
  String get tableName => 'score_logs';

  TextColumn get id => text()();

  TextColumn get scoreId =>
      text().references(BurnoutScores, #id, onDelete: KeyAction.cascade)();

  IntColumn get changeAmount => integer()();

  TextColumn get reason => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PomodoroSessionRow')
class PomodoroSessions extends Table {
  @override
  String get tableName => 'pomodoro_sessions';

  TextColumn get id => text()();

  DateTimeColumn get startTime => dateTime()();

  DateTimeColumn get endTime => dateTime().nullable()();

  IntColumn get duration => integer().nullable()();

  BoolColumn get completed => boolean().nullable()();

  TextColumn get taskLabel => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BreathingSessionRow')
class BreathingSessions extends Table {
  @override
  String get tableName => 'breathing_sessions';

  TextColumn get id => text()();

  DateTimeColumn get startedAt => dateTime()();

  IntColumn get duration => integer()();

  BoolColumn get completed => boolean()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AlertRow')
class Alerts extends Table {
  @override
  String get tableName => 'alerts';

  TextColumn get id => text()();

  TextColumn get date => text()();

  TextColumn get type => text()();

  TextColumn get message => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    UserProfiles,
    DailyEntries,
    BurnoutScores,
    BurnoutCauses,
    Tasks,
    ScoreLogs,
    PomodoroSessions,
    BreathingSessions,
    Alerts,
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase instance = AppDatabase();

  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');

        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_daily_entries_date ON ${DbTables.dailyEntries}(date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_burnout_scores_date ON ${DbTables.burnoutScores}(date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_burnout_scores_created ON ${DbTables.burnoutScores}(created_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_date ON ${DbTables.tasks}(date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_type ON ${DbTables.tasks}(task_type)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_pomodoro_start ON ${DbTables.pomodoroSessions}(start_time)',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await customStatement(
            'ALTER TABLE ${DbTables.dailyEntries} ADD COLUMN exercise_minutes INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE ${DbTables.dailyEntries} ADD COLUMN include_pomodoro_work INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (from < 3) {
          await customStatement(
            'ALTER TABLE ${DbTables.pomodoroSessions} ADD COLUMN task_label TEXT',
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'burnout_radar.db'));
    return NativeDatabase.createInBackground(file);
  });
}
