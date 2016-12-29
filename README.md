# dart_repl

A proof of concept [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) environment for dart.

## Usage

From the command-line

    dart --enable-vm-service bin/dart_repl
    
To import additional libraries:

    dart --enable-vm-service bin/repl.dart --package-dir ~/git/built_collection.dart/ --adhoc-import lib/built_collection.dart,package:test/test.dart

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
