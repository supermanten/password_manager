import 'dart:io';
import 'dart:math';
import 'package:dart_console/dart_console.dart';
import '../data/repositories/password_repository.dart';
import '../domain/entities/password_entity.dart';

class PasswordManagerCLI {
  final PasswordRepositoryImpl _repository;
  final Console console = Console();

  PasswordManagerCLI(this._repository);

  Future<void> run() async {
    while (true) {
      console.clearScreen();
      console.setForegroundColor(ConsoleColor.green);
      console.writeLine('Password Manager', TextAlignment.center);
      console.resetColorAttributes();
      console.writeLine('1. Add Password');
      console.writeLine('2. List Passwords');
      console.writeLine('3. Update Password');
      console.writeLine('4. Search Passwords');
      console.writeLine('5. Delete Password');
      console.writeLine('6. Exit');

      console.write('Select an option (1-6): ');
      final choice = console.readLine() ?? '';

      try {
        switch (choice) {
          case '1':
            await _addPassword();
            break;
          case '2':
            await _showPasswords();
            break;
          case '3':
            await _updatePassword();
            break;
          case '4':
            await _searchByWebsite();
            break;
          case '5':
            await _deletePassword();
            break;
          case '6':
            _repository.dispose();
            console.setForegroundColor(ConsoleColor.green);
            console.writeLine('Goodbye!', TextAlignment.center);
            console.resetColorAttributes();
            return;
          default:
            console.setForegroundColor(ConsoleColor.red);
            console.writeLine('Invalid option', TextAlignment.center);
            console.resetColorAttributes();
            sleep(Duration(seconds: 1));
        }
      } catch (e) {
        console.setForegroundColor(ConsoleColor.red);
        console.writeLine('Error: $e', TextAlignment.center);
        console.resetColorAttributes();
        sleep(Duration(seconds: 1));
      }
    }
  }

  String _generatePassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String _checkPasswordStrength(String password) {
    if (password.length < 8) return 'Weak';
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$%^&*]'))) return 'Strong';
    return 'Medium';
  }

  void _printPasswordStrength(String password) {
    final strength = _checkPasswordStrength(password);
    if (strength == 'Weak') {
      console.writeLine(
          'Password strength is weak. Consider a stronger password.',
          TextAlignment.center);
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('Weak', TextAlignment.center);
      console.resetColorAttributes();
    } else if (strength == 'Medium') {
      console.writeLine(
          'Password strength is medium. Consider a stronger password.',
          TextAlignment.center);
      console.setForegroundColor(ConsoleColor.yellow);
      console.writeLine('Medium', TextAlignment.center);
      console.resetColorAttributes();
    } else {
      console.writeLine('Password strength is strong.', TextAlignment.center);
      console.setForegroundColor(ConsoleColor.green);
      console.writeLine('Strong', TextAlignment.center);
      console.resetColorAttributes();
    }
  }

  String _readHiddenInput(String prompt) {
    console.write(prompt);
    stdin.echoMode = false; // Hide input
    final input = stdin.readLineSync() ?? '';
    stdin.echoMode = true; // Restore visibility
    console.writeLine(''); // Newline after hidden input
    return input;
  }

  Future<void> _addPassword() async {
    console.clearScreen();
    console.writeLine('Add Password', TextAlignment.center);
    console.write('Enter website: ');
    final website = console.readLine() ?? '';
    console.write('Enter username: ');
    final username = console.readLine() ?? '';
    final passwordInput =
        _readHiddenInput('Enter password (leave blank for random): ');
    final password =
        passwordInput.isEmpty ? _generatePassword(12) : passwordInput;

    if (website.isEmpty || username.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine(
          'Website and username are required', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    final existing = await _repository.searchByWebsite(website);
    if (existing.any((e) => e.website == website && e.username == username)) {
      console.setForegroundColor(ConsoleColor.yellow);
      console.writeLine(
          'Warning: An entry for $website/$username already exists.',
          TextAlignment.center);
      console.resetColorAttributes();
      console.write('Continue? (y/n): ');
      if ((console.readLine() ?? 'n').toLowerCase() != 'y') return;
    }

    _printPasswordStrength(password);
    _repository.addPassword(PasswordEntity(
      website: website,
      username: username,
      password: password,
    ));
    console.setForegroundColor(ConsoleColor.green);
    console.writeLine('Password saved successfully', TextAlignment.center);
    if (passwordInput.isEmpty) {
      console.writeLine('Generated password: $password', TextAlignment.center);
    }
    console.resetColorAttributes();
    console.writeLine('Press Enter to return...');
    console.readLine();
  }

  Future<void> _showPasswords() async {
    final passwords = await _repository.getAllPasswords();
    console.clearScreen();
    console.writeLine('Stored Passwords', TextAlignment.center);

    if (passwords.isEmpty) {
      console.setForegroundColor(ConsoleColor.yellow);
      console.writeLine('No passwords stored', TextAlignment.center);
      console.resetColorAttributes();
    } else {
      final table = Table()
        ..borderStyle = BorderStyle.square
        ..borderType = BorderType.horizontal;

      table.insertRow([
        '\x1B[1mID\x1B[0m',
        '\x1B[1mWebsite\x1B[0m',
        '\x1B[1mUsername\x1B[0m',
        '\x1B[1mPassword\x1B[0m'
      ]); // Add data rows
      for (final entry in passwords) {
        table.insertRow([
          entry.id.toString(),
          entry.website,
          entry.username,
          entry.password
        ]);
      }

      console.write(table);
    }
    console.writeLine('\nPress Enter to return...');
    console.readLine();
  }

  Future<void> _deletePassword() async {
    final passwords = await _repository.getAllPasswords();
    console.clearScreen();
    console.writeLine('Delete Password', TextAlignment.center);

    if (passwords.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('No passwords stored', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    console.write('Enter password ID to delete: ');
    final idStr = console.readLine() ?? '';
    final id = int.tryParse(idStr);

    if (id == null) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('Invalid ID', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    try {
      _repository.deletePassword(id);
      console.setForegroundColor(ConsoleColor.green);
      console.writeLine('Password deleted successfully', TextAlignment.center);
      console.resetColorAttributes();
    } catch (e) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('Delete failed: $e', TextAlignment.center);
      console.resetColorAttributes();
    }
    sleep(Duration(seconds: 1));
  }

  Future<void> _updatePassword() async {
    final passwords = await _repository.getAllPasswords();
    console.clearScreen();
    console.writeLine('Update Password', TextAlignment.center);

    if (passwords.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('No passwords stored', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    console.write('Enter password ID to update: ');
    final idStr = console.readLine() ?? '';
    final id = int.tryParse(idStr);

    if (id == null) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('Invalid ID', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    final entryToUpdate = passwords.firstWhere(
      (entry) => entry.id == id,
      orElse: () =>
          PasswordEntity(id: null, website: '', username: '', password: ''),
    );
    if (entryToUpdate.id == null) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('No password found with ID $id', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    console.writeLine('Current Entry:', TextAlignment.center);
    console.writeLine('Website: ${entryToUpdate.website}');
    console.writeLine('Username: ${entryToUpdate.username}');
    console.writeLine('Password: ${entryToUpdate.password}');
    console.writeLine(
        'Leave blank to keep current value.', TextAlignment.center);

    console.write('Enter new website: ');
    final website = console.readLine() ?? '';
    console.write('Enter new username: ');
    final username = console.readLine() ?? '';
    final password = _readHiddenInput('Enter new password: ');

    final updatedEntry = PasswordEntity(
      id: id,
      website: website.isEmpty ? entryToUpdate.website : website,
      username: username.isEmpty ? entryToUpdate.username : username,
      password: password.isEmpty ? entryToUpdate.password : password,
    );

    _printPasswordStrength(updatedEntry.password);

    await _repository.updatePassword(updatedEntry);
    console.setForegroundColor(ConsoleColor.green);
    console.writeLine('Password updated successfully', TextAlignment.center);
    console.resetColorAttributes();
    console.writeLine('Press Enter to return...');
    console.readLine();
  }

  Future<void> _searchByWebsite() async {
    final passwords = await _repository.getAllPasswords();
    console.clearScreen();
    console.writeLine('Search Passwords', TextAlignment.center);

    if (passwords.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('No passwords stored', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    console.write('Enter website name to search: ');
    final searchTerm = console.readLine() ?? '';

    final matches = await _repository.searchByWebsite(searchTerm);
    if (matches.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine('No matching records found for website "$searchTerm"',
          TextAlignment.center);
      console.resetColorAttributes();
    } else {
      final table = Table()
        ..borderStyle = BorderStyle.square
        ..borderType = BorderType.horizontal;

      table.insertRow([
        '\x1B[1mID\x1B[0m',
        '\x1B[1mWebsite\x1B[0m',
        '\x1B[1mUsername\x1B[0m',
        '\x1B[1mPassword\x1B[0m'
      ]);
      for (final entry in matches) {
        table.insertRow([
          entry.id.toString(),
          entry.website,
          entry.username,
          entry.password
        ]);
      }

      console.writeLine('Matching Records:', TextAlignment.center);
      console.write(table);
    }
    console.writeLine('\nPress Enter to return...');
    console.readLine();
  }
}
