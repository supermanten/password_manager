import 'dart:io';
import 'dart:math';
import 'package:dart_console/dart_console.dart';
import '../data/repositories/password_repository.dart';
import '../domain/entities/password_entity.dart';

String generatePassword(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  final random = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}

String checkPasswordStrength(String password) {
  if (password.length < 8) return 'Weak';
  if (password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[0-9]')) &&
      password.contains(RegExp(r'[!@#\$%^&*]'))) {
    return 'Strong';
  }
  return 'Medium';
}

void printPasswordStrength(Console console, String password) {
  final strength = checkPasswordStrength(password);
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

String readHiddenInput(Console console, String prompt) {
  console.write(prompt);
  stdin.echoMode = false;
  final input = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  console.writeLine('');
  return input;
}

Future<void> editPassword(Console console, PasswordRepositoryImpl repository,
    PasswordEntity entry) async {
  console.clearScreen();
  console.writeLine('Edit Password: ID ${entry.id}', TextAlignment.center);
  console.writeLine('Current Entry:', TextAlignment.center);
  console.writeLine('Website: ${entry.website}');
  console.writeLine('Username: ${entry.username}');
  console.writeLine('Password: ${entry.password}');
  console.writeLine('Leave blank to keep current value.', TextAlignment.center);

  console.write('Enter new website: ');
  final website = console.readLine() ?? '';
  console.write('Enter new username: ');
  final username = console.readLine() ?? '';
  final password = readHiddenInput(console, 'Enter new password: ');

  final updatedEntry = PasswordEntity(
    id: entry.id,
    website: website.isEmpty ? entry.website : website,
    username: username.isEmpty ? entry.username : username,
    password: password.isEmpty ? entry.password : password,
  );

  printPasswordStrength(console, updatedEntry.password);
  await repository.updatePassword(updatedEntry);
  console.setForegroundColor(ConsoleColor.green);
  console.writeLine('Password updated successfully', TextAlignment.center);
  console.resetColorAttributes();
  console.writeLine('Press Enter to return...');
  console.readLine();
}

Future<PasswordEntity?> selectPassword(
    Console console, List<PasswordEntity> passwords) async {
  if (passwords.isEmpty) {
    console.setForegroundColor(ConsoleColor.yellow);
    console.writeLine('No passwords to display', TextAlignment.center);
    console.resetColorAttributes();
    console.writeLine('Press Enter to return...');
    console.readLine();
    return null;
  }

  int selectedIndex = 0;
  bool exit = false;

  while (!exit) {
    console.clearScreen();
    console.writeLine('Passwords (↑↓ to navigate, Enter to select, q to quit)',
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
    console.writeLine('Select an entry...');

    final key = console.readKey();
    if (key.char == 'q') {
      exit = true;
    } else if (key.isControl && key.controlChar == ControlCharacter.enter) {
      return passwords[selectedIndex];
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
  return null;
}
