import 'dart:convert';
import 'package:file_picker/file_picker.dart';

Future<String?> pickImportJsonFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;
  final bytes = result.files.single.bytes;
  if (bytes == null) return null;
  return utf8.decode(bytes, allowMalformed: true);
}
