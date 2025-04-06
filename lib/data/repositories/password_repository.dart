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
      _database = sqlite3.open(dbPath);

      _database.execute('''
        CREATE TABLE IF NOT EXISTS passwords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          website TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL
        )
      ''');
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
    } catch (e) {
      throw Exception('Failed to add password: $e');
    }
  }

  @override
  Future<List<PasswordEntity>> getAllPasswords() async {
    try {
      final result = _database.select('SELECT * FROM passwords');
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
      final affectedRows = _database.updatedRows;
      if (affectedRows == 0) {
        throw Exception('No password found with ID $id');
      }
      // Check if table is empty and reset sequence
      final count = _database
          .select('SELECT COUNT(*) as count FROM passwords')
          .first['count'] as int;
      if (count == 0) {
        _database
            .execute('DELETE FROM sqlite_sequence WHERE name = "passwords"');
      }
    } catch (e) {
      throw Exception('Failed to delete password: $e');
    }
  }

  @override
  Future<void> updatePassword(PasswordEntity entry) async {
    try {
      if (entry.id == null) {
        throw Exception('Cannot update: ID is required');
      }

      _database.execute(
        'UPDATE passwords SET website = ?, username = ?, password = ? WHERE id = ?',
        [entry.website, entry.username, entry.password, entry.id],
      );
      final affectedRows = _database.updatedRows;

      if (affectedRows == 0) {
        throw Exception('No password found with ID ${entry.id}');
      }
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  @override
  Future<List<PasswordEntity>> searchByWebsite(String website) async {
    try {
      final result = _database.select(
        'SELECT * FROM passwords WHERE website LIKE ?',
        ['%$website%'], // Using LIKE with wildcards for partial matches
      );
      return result.map((row) {
        return PasswordEntity(
          id: row['id'] as int?,
          website: row['website'] as String,
          username: row['username'] as String,
          password: row['password'] as String,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to search passwords: $e');
    }
  }

  void dispose() {
    _database.dispose();
  }
}
