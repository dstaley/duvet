import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:coverage/coverage.dart' as coverage;
import './types.dart';
import './elements.dart';

typedef bool _PathFilter(String path);
_PathFilter _getPathFilter(List<String> reportOn) {
  if (reportOn == null) return (String path) => true;

  var absolutePaths = reportOn.map(path.absolute).toList();
  return (String path) => absolutePaths.any((item) => path.startsWith(item));
}

/// Get the absolute path to the `test` package.
Future<String> resolveTestPackageLocation() async {
  try {
    var dotPackages = await File('.packages').readAsString();
    var testPackageLocation = dotPackages
        .split('\n')
        .where((l) => l.startsWith("test:"))
        .toList()[0]
        .substring(12);
    return testPackageLocation;
  } catch (e) {
    return null;
  }
}

/// Exception class for when `test` package isn't installed.
class PackageNotFoundException implements Exception {
  /// Create an instance of PackageNotFoundException.
  PackageNotFoundException(this.message);

  /// The error message for this exception.
  String message;
}

/// Execute `pub run test` in the current directory, and collect coverage from
/// the Dart VM.
Future<Map<String, List<LineReport>>> runTests() async {
  var testPackageLocation = await resolveTestPackageLocation();
  if (testPackageLocation == null) {
    throw PackageNotFoundException(
        'Unable to locate test package. Please add `test` to your pubspec.yml and run this command again.');
  }
  var dartArgs = [
    '--pause-isolates-on-exit',
    '--enable-vm-service=8111',
    '--packages=.packages',
    '$testPackageLocation/src/executable.dart',
  ];

  var process = await Process.start('dart', dartArgs);
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  var serviceUri = Uri.parse('http://127.0.0.1:8111/');
  Map<String, List<LineReport>> report = {};
  final data = await coverage.collect(serviceUri, true, true);
  var hitmap = coverage.createHitmap(data['coverage']);
  final resolver = new coverage.Resolver(
    packagesPath: path.join(Directory.current.path, '.packages'),
  );
  _PathFilter pathFilter = _getPathFilter(['lib${path.separator}']);
  var loader = coverage.Loader();
  for (var k in hitmap.keys) {
    var source = resolver.resolve(k);
    if (source == null) {
      continue;
    }

    if (!pathFilter(source)) {
      continue;
    }

    var sourceCode = await loader.load(source);
    List<LineReport> lineReports = [];
    for (var line = 0; line < sourceCode.length; line++) {
      lineReports.add(LineReport(
        line + 1,
        sourceCode[line],
        hitmap[k].containsKey(line + 1) ? hitmap[k][line + 1] : null,
      ));
    }
    report[source] = lineReports;
  }
  return report;
}

/// Generate and write a coverage report for a single source file.
Future<FileCoverageReport> generateAndWriteReport({
  @required String sourceFilePath,
  @required List<LineReport> lineReports,
  @required String outputDir,
}) async {
  var output =
      sourceFilePath.replaceFirst(Directory.current.path + path.separator, '') +
          '.html';
  var outputPath = path.join(outputDir, output);
  var outputFile = File(outputPath);
  if (!outputFile.existsSync()) {
    await outputFile.create(recursive: true);
  }
  var fileReport = FileCoverageReport(sourceFilePath, lineReports);
  var doc = document(
    children: [
      header(fileReport.prettyPath, [fileReport]),
      reportElement(lineReports),
      footer(),
    ],
  );
  await outputFile.writeAsString(doc.toString());
  return fileReport;
}

/// Generate the root HTML element that lists each tested file and coverage.
Future<void> generateAndWriteIndex({
  @required String outputDir,
  @required List<FileCoverageReport> reports,
}) async {
  await File(path.join(outputDir, 'index.html'))
      .writeAsString(index(reports).toString());
}
