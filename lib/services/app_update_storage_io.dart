import 'dart:io';

Future<String> saveApkToTemp(
  String dirPath,
  String name,
  List<int> bytes,
) async {
  final safe = name.replaceAll(RegExp(r'[/\\]'), '_');
  final file = File('$dirPath/$safe');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
