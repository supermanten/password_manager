import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../domain/entities/password_entity.dart';
import '../../domain/repositories/password_repository.dart';

class PasswordRepositoryImpl implements PasswordRepository {
  late final Database _database;

  PasswordRepositoryImpl() {
    _initDatabase();
  }

  void _initDatabase() {
    try {
      final dbPath = join(Directory.current.path, 'passwords.db');
      print('Database path: $dbPath'); // Debug
      _database = sqlite3.open(dbPath);

      _database.execute('''
        CREATE TABLE IF NOT EXISTS passwords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          website TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL
        )
      ''');
      print('Database initialized'); // Debug
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  @override
  Future<void> addPassword(PasswordEntity entry) async {
    try {
      _database.execute(
        'INSERT INTO passwords (website, username, password) VALUES (?, ?, ?)',
        [entry.website, entry.username, entry.password],
      );
      print('Added: ${entry.website}, ${entry.username}'); // Debug
    } catch (e) {
      throw Exception('Failed to add password: $e');
    }
  }

  @override
  Future<List<PasswordEntity>> getAllPasswords() async {
    try {
      final result = _database.select('SELECT * FROM passwords');
      print('Retrieved ${result.length} rows'); // Debug
      return result.map((row) {
        return PasswordEntity(
          id: row['id'] as int?,
          website: row['website'] as String,
          username: row['username'] as String,
          password: row['password'] as String,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get passwords: $e');
    }
  }

  @override
  Future<void> deletePassword(int id) async {
    try {
      _database.execute(
        'DELETE FROM passwords WHERE id = ?',
        [id],
      );
      final affectedRows =
          _database.updatedRows; // Get affected rows after execute
      print(
          'Delete attempted for ID $id, affected rows: $affectedRows'); // Debug
      if (affectedRows == 0) {
        throw Exception('No password found with ID $id');
      }
    } catch (e) {
      throw Exception('Failed to delete password: $e');
    }
  }

  void dispose() {
    _database.dispose();
    print('Database disposed'); // Debug
  }
}

