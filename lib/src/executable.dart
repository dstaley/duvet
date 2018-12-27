import 'dart:io';
import 'package:args/args.dart';
import 'package:shelf/shelf_io.dart' as shelf;
import 'package:shelf_static/shelf_static.dart';
import './duvet_base.dart';
import './types.dart';

void main(List<String> args) async {
  var parser = ArgParser();
  parser
    ..addOption(
      'outputDir',
      abbr: 'o',
      defaultsTo: 'coverage',
      help:
          'The directory where you would like coverage info to be written to.',
    )
    ..addFlag(
      'serve',
      abbr: 's',
      defaultsTo: false,
      help:
          'Whether you would like duvet to start a web server and serve the coverage info.',
      negatable: false,
    )
    ..addOption(
      'port',
      abbr: 'p',
      defaultsTo: '8080',
      help: 'The port to use when --serve is used.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      defaultsTo: false,
      help: 'Print usage information for duvet.',
      negatable: false,
    );

  final options = parser.parse(args);

  if (options['help'] == true) {
    print(parser.usage);
    return;
  }

  final outputDir = options['outputDir'];
  if (!FileSystemEntity.isDirectorySync(outputDir)) {
    await Directory(outputDir).create();
  }

  List<FileCoverageReport> reports = [];
  var report = await runTests();
  for (var k in report.keys) {
    var fileReport = await generateAndWriteReport(
      sourceFilePath: k,
      lineReports: report[k],
      outputDir: outputDir,
    );
    reports.add(fileReport);
  }

  await generateAndWriteIndex(outputDir: outputDir, reports: reports);

  if (options['serve'] == true) {
    var handler = createStaticHandler(options['outputDir'],
        defaultDocument: 'index.html');

    shelf
        .serve(handler, 'localhost', int.parse(options['port']))
        .then((server) {
      print('Serving at http://${server.address.host}:${server.port}');
    });
  }
}
