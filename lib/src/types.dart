import 'dart:io';
import 'package:path/path.dart' as path;

/// Represents a coverage report for a specific line of code.
class LineReport {
  /// Create a LineReport.
  LineReport(this.lineNumber, this.code, this.hits);

  /// The line number for which this LineReport is reporting coverage.
  int lineNumber;

  /// The source code of the line.
  String code;

  /// The number of times the line was executed.
  int hits;
}

/// Coverage statistics for a source file.
class FileStatistics {
  /// Create a FileStatistics representation.
  FileStatistics(this.linesFound, this.linesHit);

  /// The number of executable lines found in the source file.
  int linesFound;

  /// The number of executable lines that were executed at least once in the
  /// source file.
  int linesHit;

  /// Returns the coverage of the file as a human-friendly percentage (69.8).
  double get percentage {
    return (linesHit / linesFound) * 100;
  }

  /// Returns the coverage of the file as a human-friendly percentage string
  /// (69.8%).
  String get percentageAsString {
    return "${percentage.toStringAsFixed(1)}%";
  }
}

/// The coverage report for a specific source file.
class FileCoverageReport {
  /// Create a FileCoverageReprot.
  FileCoverageReport(this.filepath, this.report) {
    stats = FileStatistics(
      report.where((lr) => lr.hits != null).length,
      report.where((lr) => lr.hits != null && lr.hits > 0).length,
    );
  }

  /// The full filepath to the source file being reported on.
  String filepath;

  /// The LineReports for each line in the source file.
  List<LineReport> report;

  /// Coverage statistics for the source file.
  FileStatistics stats;

  /// The path to the file with the current directory removed.
  String get prettyPath {
    return filepath.replaceFirst(Directory.current.path + path.separator, '');
  }
}
