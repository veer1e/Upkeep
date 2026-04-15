import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> shareExportFile({
  required String filename,
  required String content,
}) async {
  if (kIsWeb) return false;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content, flush: true);

  final shareResult = await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json')],
    text: 'Life Maintenance export data',
    subject: 'Life Maintenance export',
  );

  return shareResult.status == ShareResultStatus.success ||
      shareResult.status == ShareResultStatus.dismissed;
}
