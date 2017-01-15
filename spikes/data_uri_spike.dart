import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

Uri createDartUri(String script) {
  return new Uri.dataFromString(script,
      encoding: UTF8, mimeType: 'application/dart');
}

Future main() async {
  final envCode = createDartUri("var result;");
  final importA = createDartUri("""
    import "${envCode}";

    var a = 1;

    void f() {
      print(a);
    }

    """);
  final importB = createDartUri("""
    import "${envCode}";
    import "${importA}";
    export "${importA}";

    var a = 2;
  """);

  final exitReceiver = new ReceivePort();
  final isolate = await Isolate.spawnUri(createDartUri("""
    import "${importB}";

    void main() {
      print("hello world");
      print(a);
      f();
    }
    """), [], null, onExit: exitReceiver.sendPort);
  await exitReceiver.drain<Null>();
}
