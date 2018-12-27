import 'package:hyper/hyper.dart';
import 'package:hyper/elements.dart' as h;
import 'package:path/path.dart' as path;
import 'package:sass/sass.dart' as sass;
import './types.dart';

/// The stylesheet for coverage reports.
var stylesheet = sass.compileString(r'''
  $red: #e06c75;
  $yellow: #e5c07b;
  $green: #98c379;

  $background-dark: #21252b;
  $background: #282c34;

  $text-color: #bbbbbb;

  html, body {
    margin: 0;
  }

  body {
    background-color: $background;
    color: $text-color;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"
  }

  code, .codeView {
    font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  }

  pre {
    margin: 0;
  }

  .codeView {
    width: 100%;
    border-collapse: collapse;
    border: none;
    font-size: 12px;
    margin-top: 16px;
  }

  .noop code {
    opacity: 0.5;
  }

  .miss {
    background-color: rgba($red, 0.25);
  }

  .hit {
    background-color: rgba($green, 0.25);
  }

  .codeView td {
    padding: 2px 5px;
  }

  .lineNumber, .executionCount {
    text-align: right;
    width: 1px;
    white-space: nowrap;
    border-right: 1px solid rgba($text-color, 0.25);
  }

  .lineNumber {
    padding-left: 15px;
    color: rgba($text-color, 0.25);
  }

  .hit .lineNumber,
  .miss .lineNumber {
    color: $text-color;
  }

  a {
    color: $text-color;

    &:visited {
      color: $text-color;
    }
  }

  .fileListing {
    display: flex;
    justify-content: center;
    margin-top: 16px;
    margin-bottom: 32px;

    thead {
      background-color: $background-dark;
    }

    th, td {
      padding: 8px 0;
    }

    .filename {
      text-align: right;
    }
  }

  progress {
    width: 100%;
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;
    border: none;
  }

  progress.progressLow[value]::-moz-progress-bar {
    background-color: $red;
  }

  progress.progressLow[value]::-webkit-progress-value {
    background-color: $red;
  }

  progress.progressMedium[value]::-webkit-progress-value {
    background-color: $yellow;
  }

  progress.progressMedium[value]::-moz-progress-bar {
    background-color: $yellow;
  }

  progress.progressHigh[value]::-webkit-progress-value {
    background-color: $green;
  }

  progress.progressHigh[value]::-moz-progress-bar {
    background-color: $green;
  }

  td.coverageVisual {
    width: 200px;
    padding-left: 16px;
  }

  .filename,
  .coveragePercent,
  .coverageNumeric,
  .coverageVisual {
    width: 1px;
    white-space: nowrap;
  }

  header, footer {
    background-color: $background-dark;
    color: $text-color;
  }

  header {
    box-shadow: rgba(0, 0, 0, 0.2) 0px 3px 1px -2px, rgba(0, 0, 0, 0.14) 0px 2px 2px 0px, rgba(0, 0, 0, 0.12) 0px 1px 5px 0px;
    padding: 16px;

    h1 {
      margin-top: 0px;
      font-size: 24px;
    }
  }

  footer p {
    text-align: center;
    margin: 0;
    padding: 16px 0;
  }

  td.filename {
    padding-right: 16px;
  }

  .coverageChip {
    padding: 5px;
    border-radius: 4px;
    color: $background-dark;

    &.high {
      background-color: $green;
    }

    &.medium {
      background-color: $yellow;
    }

    &.low {
      background-color: $red;
    }
  }
''');

/// Get the class name for a specific level of coverage.
String classNameForCoveragePercent(
    double percentage, String high, String medium, String low) {
  return percentage >= 90 ? high : percentage >= 75 ? medium : low;
}

/// Calculate FileStatistics for multiple FileCoverageReports. Used to
/// calculate the project-level coverage.
FileStatistics calculateTotalCoverage(List<FileCoverageReport> reports) {
  var linesFound = 0;
  var linesHit = 0;
  reports.forEach((r) {
    linesFound += r.stats.linesFound;
    linesHit += r.stats.linesHit;
  });

  return FileStatistics(linesFound, linesHit);
}

/// Generate a base HTML document containing the title and stylesheet.
Element document({List<Element> children}) {
  return hyper('html', children: [
    h.head(children: [
      h.title(children: [t('Duvet Coverage Report')]),
      h.style(children: [t(stylesheet)])
    ]),
    h.body(children: children)
  ]);
}

/// Generate a line of the source code report.
Element reportLine(LineReport line) {
  return h.tr(attrs: {
    'class': line.hits == null ? 'noop' : line.hits == 0 ? 'miss' : 'hit'
  }, children: [
    h.td(
      attrs: {'class': 'lineNumber'},
      children: [t(line.lineNumber.toString())],
    ),
    h.td(
      attrs: {'class': 'executionCount'},
      children: line.hits == null ? [] : [t(line.hits.toString())],
    ),
    h.td(
      children: [
        h.pre(children: [
          h.code(children: [t(line.code)])
        ])
      ],
    ),
  ]);
}

/// Generate the table that displays the source code of the file.
Element reportElement(List<LineReport> lineReports) {
  return h.table(
    attrs: {'class': 'codeView'},
    children: [
      h.tbody(
        children: lineReports.map((r) => reportLine(r)).toList(),
      )
    ],
  );
}

/// Generate the file listing that appears in the root document.
Element fileListing(List<FileCoverageReport> reports) {
  reports.sort((a, b) {
    var firstSort =
        b.filepath.split('').where((c) => c == path.separator).length -
            a.filepath.split('').where((c) => c == path.separator).length;
    if (firstSort == 0) {
      return a.filepath.compareTo(b.filepath);
    }

    return firstSort;
  });

  return h.div(
    attrs: {'class': 'fileListing'},
    children: [
      h.table(
        children: [
          h.thead(
            children: [
              h.tr(
                children: [
                  h.th(
                    children: [
                      t('File'),
                    ],
                  ),
                  h.th(
                    attrs: {
                      'colspan': '2',
                    },
                    children: [
                      t('Line Coverage'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          h.tbody(
            children: reports.map((r) {
              final pathToOutputFile = r.prettyPath + '.html';
              final stats = r.stats;
              return h.tr(
                children: [
                  h.td(
                    attrs: {'class': 'filename'},
                    children: [
                      h.a(
                        attrs: {'href': '/' + pathToOutputFile},
                        children: [t(r.prettyPath)],
                      )
                    ],
                  ),
                  h.td(
                    children: [
                      t("${stats.linesHit} / ${stats.linesFound} (${stats.percentageAsString})")
                    ],
                  ),
                  h.td(
                    attrs: {'class': 'coverageVisual'},
                    children: [
                      h.progress(
                        attrs: {
                          'class': classNameForCoveragePercent(
                            r.stats.percentage,
                            'progressHigh',
                            'progressMedium',
                            'progressLow',
                          ),
                          'max': r.stats.linesFound.toString(),
                          'value': r.stats.linesHit.toString()
                        },
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ],
  );
}

/// Generate the header that appears on every page.
Element header(String path, List<FileCoverageReport> reports) {
  var summedCoverage = calculateTotalCoverage(reports);
  return h.header(
    children: [
      h.h1(children: [t("Coverage report for $path")]),
      h.p(
        attrs: {'class': 'coverage'},
        children: [
          t('Line coverage: '),
          h.span(
            attrs: {
              'class': "coverageChip ${classNameForCoveragePercent(
                summedCoverage.percentage,
                'high',
                'medium',
                'low',
              )}"
            },
            children: [
              t("${summedCoverage.linesHit} / ${summedCoverage.linesFound} (${summedCoverage.percentageAsString})")
            ],
          ),
        ],
      ),
      h.p(
        attrs: {'style': path == 'All files' ? 'display: none' : ''},
        children: [
          h.a(attrs: {'href': '/'}, children: [t('All files')]),
          t(' > ' + path)
        ],
      )
    ],
  );
}

/// Generate the footer that appears on every page.
Element footer() {
  return h.footer(
    children: [
      h.p(
        children: [
          t('Coverage report generated by '),
          h.a(
            attrs: {'href': 'https://pub.dartlang.org/packages/duvet'},
            children: [t('Duvet')],
          ),
          t('.'),
        ],
      ),
    ],
  );
}

/// Generate an HTML document containing a file listing of every tested file.
Element index(List<FileCoverageReport> reports) {
  return document(
    children: [header('All files', reports), fileListing(reports), footer()],
  );
}
