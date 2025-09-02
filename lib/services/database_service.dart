import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/equipment.dart';
import '../models/checklist_task.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'field_services.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Equipment table
        await db.execute('''
          CREATE TABLE equipment(
            id TEXT PRIMARY KEY,
            serialNumber TEXT NOT NULL,
            partNumber TEXT NOT NULL,
            partName TEXT NOT NULL,
            customerNumber TEXT NOT NULL,
            customerName TEXT NOT NULL,
            rfidData TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        // Checklist tasks table (for temporary storage)
        await db.execute('''
          CREATE TABLE checklist_tasks(
            id TEXT PRIMARY KEY,
            equipmentId TEXT NOT NULL,
            category TEXT NOT NULL,
            task TEXT NOT NULL,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            photoPath TEXT,
            completedBy TEXT,
            completedAt TEXT,
            FOREIGN KEY (equipmentId) REFERENCES equipment (id)
          )
        ''');
      },
    );
  }

  Future<void> insertEquipment(Equipment equipment) async {
    final db = await database;
    await db.insert(
      'equipment',
      equipment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Equipment?> getEquipment(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Equipment.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertChecklistTask(ChecklistTask task) async {
    final db = await database;
    await db.insert(
      'checklist_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChecklistTask>> getChecklistTasks(String equipmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checklist_tasks',
      where: 'equipmentId = ?',
      whereArgs: [equipmentId],
      orderBy: 'category, task',
    );

    return maps.map((map) => ChecklistTask.fromMap(map)).toList();
  }

  Future<void> updateChecklistTask(ChecklistTask task) async {
    final db = await database;
    await db.update(
      'checklist_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> clearTemporaryData() async {
    final db = await database;
    await db.delete('checklist_tasks');
    await db.delete('equipment');
  }
}