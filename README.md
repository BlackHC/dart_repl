# dart_repl

A proof of concept [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) environment for Dart.

[![asciicast](https://asciinema.org/a/2wxg2qpnlcaw4dpoo6o2c705s.png)](https://asciinema.org/a/2wxg2qpnlcaw4dpoo6o2c705s)

See the [Dart REPL Directions brain-dump](https://docs.google.com/document/d/1gDkF1meFpsQO_X_SCoAxdsdCNVhPiAz4HLyvvzOXWKU/edit?usp=sharing) for possible ideas and directions.

## Usage

## From another package

You can add a `dev_dependency:` to your `pubspec.yaml`:

```
dev_dependencies:
  dart_repl:
  [...]
```

You can then run the REPL with:

    pub run dart_repl

It will automatically resolve all additional adhoc imports against the dependencies of your package: 

    pub run dart_repl --adhoc-import package:built_collection/built_collection.dart

## From a checkout

From the command-line

    dart bin/dart_repl.dart

To import additional libraries:

    dart bin/dart_repl.dart --package-dir ~/git/built_collection.dart/ --adhoc-import lib/built_collection.dart

## `pub global run` is currently not supported

`pub global run` only provides a packageRoot and packages are served via a web service. This special case is not 
handled at the moment, so it will fail to start. Contributions are welcome!

## Features requests and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/BlackHC/dart_repl/issues
