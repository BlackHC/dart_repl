import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

Future<String> readUrl(Uri uri) async {
  if (uri.scheme == 'file') {
    return new File(uri.toFilePath()).readAsStringSync();
  }
  final request = await new HttpClient().getUrl(uri);
  final response = await request.close();
  final contentPieces = await response.transform(new Utf8Decoder()).toList();
  final content = contentPieces.join();
  return content;
}

Future main() async {
  print(await readUrl(await Isolate.packageConfig));
}
