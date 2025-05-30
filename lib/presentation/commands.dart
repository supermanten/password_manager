import 'dart:io';

import 'package:dart_console/dart_console.dart';
import '../domain/entities/password_entity.dart';
import '../domain/repositories/password_repository.dart';
import 'utils.dart' as utils;

abstract class Command {
  Future<void> execute(Console console, PasswordRepository repository);
}

class AddPasswordCommand implements Command {
  @override
  Future<void> execute(Console console, PasswordRepository repository) async {
    console.clearScreen();
    console.writeLine('Add Password', TextAlignment.center);
    console.write('Enter website: ');
    final website = console.readLine() ?? '';
    console.write('Enter username: ');
    final username = console.readLine() ?? '';
    final passwordInput = utils.readHiddenInput(
        console, 'Enter password (leave blank for random): ');
    final password =
        passwordInput.isEmpty ? utils.generatePassword(12) : passwordInput;

    if (website.isEmpty || username.isEmpty) {
      console.setForegroundColor(ConsoleColor.red);
      console.writeLine(
          'Website and username are required', TextAlignment.center);
      console.resetColorAttributes();
      sleep(Duration(seconds: 1));
      return;
    }

    final existing = await repository.searchByWebsite(website);
    if (existing.any((e) => e.website == website && e.username == username)) {
      console.setForegroundColor(ConsoleColor.yellow);
      console.writeLine(
          'Warning: An entry for $website/$username already exists.',
          TextAlignment.center);
      console.resetColorAttributes();
      console.write('Continue? (y/n): ');
      if ((console.readLine() ?? 'n').toLowerCase() != 'y') return;
    }

    utils.printPasswordStrength(console, password);
    repository.addPassword(PasswordEntity(
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
}

class ListPasswordsCommand implements Command {
  @override
  Future<void> execute(Console console, PasswordRepository repository) async {
    final passwords = await repository.getAllPasswords();
    if (passwords.isEmpty) {
      console.clearScreen();
      console.setForegroundColor(ConsoleColor.yellow);
      console.writeLine('No passwords stored', TextAlignment.center);
      console.resetColorAttributes();
      console.writeLine('Press Enter to return...');
      console.readLine();
      return;
    }

    int selectedIndex = 0;
    bool exit = false;

    while (!exit) {
      console.clearScreen();
      console.writeLine(
          'Stored Passwords (↑↓ to navigate, Enter to select, q to quit)',
          TextAlignment.center);

      final table = Table()
        ..borderStyle = BorderStyle.rounded
        ..borderType = BorderType.horizontal
        ..insertRow(['ID', 'Website', 'Username', 'Password']);

      for (int i = 0; i < passwords.length; i++) {
        final row = [
          passwords[i].id.toString(),
          passwords[i].website,
          passwords[i].username,
          passwords[i].password
        ];
        if (i == selectedIndex) {
          table.insertRow(row.map((cell) => '\x1B[44m$cell\x1B[0m').toList());
        } else {
          table.insertRow(row);
        }
      }

      console.write(table);
      console.writeLine('Select an entry to edit/delete...');

      final key = console.readKey();
      if (key.char == 'q') {
        exit = true;
      } else if (key.isControl && key.controlChar == ControlCharacter.enter) {
        final selectedEntry = passwords[selectedIndex];
        console.clearScreen();
        console.writeLine(
            'Selected Entry: ID ${selectedEntry.id}', TextAlignment.center);
        console.writeLine('1. Edit');
        console.writeLine('2. Delete');
        console.writeLine('3. Back');
        console.write('Choose an action (1-3): ');
        final action = console.readLine() ?? '';

        switch (action) {
          case '1':
            await utils.editPassword(console, repository, selectedEntry);
            return;
          case '2':
            await repository.deletePassword(selectedEntry.id!);
            console.setForegroundColor(ConsoleColor.green);
            console.writeLine(
                'Password deleted successfully', TextAlignment.center);
            console.resetColorAttributes();
            sleep(Duration(seconds: 1));
            return;
          case '3':
            break;
          default:
            console.setForegroundColor(ConsoleColor.red);
            console.writeLine('Invalid action', TextAlignment.center);
            console.resetColorAttributes();
            sleep(Duration(seconds: 1));
        }
      } else if (key.isControl) {
        if (key.controlChar == ControlCharacter.arrowUp && selectedIndex > 0) {
          selectedIndex--;
        }
        if (key.controlChar == ControlCharacter.arrowDown &&
            selectedIndex < passwords.length - 1) {
          selectedIndex++;
        }
      }
    }
  }
}

class SearchPasswordsCommand implements Command {
  @override
  Future<void> execute(Console console, PasswordRepository repository) async {
    console.clearScreen();
    console.writeLine('Search Passwords', TextAlignment.center);
    console.write('Enter website name to search: ');
    final searchTerm = console.readLine() ?? '';
    final matches = await repository.searchByWebsite(searchTerm);
    final selectedEntry = await utils.selectPassword(console, matches);
    if (selectedEntry != null) {
      // Same as above: handle edit or delete
      console.clearScreen();
      console.writeLine(
          'Selected Entry: ID ${selectedEntry.id}', TextAlignment.center);
      console.writeLine('1. Edit');
      console.writeLine('2. Delete');
      console.writeLine('3. Back');
      console.write('Choose an action (1-3): ');
      final action = console.readLine() ?? '';

      switch (action) {
        case '1':
          await utils.editPassword(console, repository, selectedEntry);
          break;
        case '2':
          await repository.deletePassword(selectedEntry.id!);
          console.setForegroundColor(ConsoleColor.green);
          console.writeLine(
              'Password deleted successfully', TextAlignment.center);
          console.resetColorAttributes();
          sleep(Duration(seconds: 1));
          break;
        case '3':
          break;
        default:
          console.setForegroundColor(ConsoleColor.red);
          console.writeLine('Invalid action', TextAlignment.center);
          console.resetColorAttributes();
          sleep(Duration(seconds: 1));
      }
    }
  }
}

class DeletePasswordCommand implements Command {
  @override
  Future<void> execute(Console console, PasswordRepository repository) async {
    final passwords = await repository.getAllPasswords();
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
      await repository.deletePassword(id);
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
}

class UpdatePasswordCommand implements Command {
  @override
  Future<void> execute(Console console, PasswordRepository repository) async {
    final passwords = await repository.getAllPasswords();
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

    await utils.editPassword(console, repository, entryToUpdate);
  }
}
