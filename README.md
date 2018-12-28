# Duvet

Duvet generates nice-looking coverage reports for your Dart projects.

![Duvet coverage report screenshot](https://raw.githubusercontent.com/dstaley/duvet/master/site/screenshot.png)

## Installation

Add Duvet to your project by adding the following to your `pubspec.yaml`:

```yml
dev_dependencies:
  duvet: ^1.0.0
```

You can also install `duvet` globally with the following:

```bash
$ pub global activate duvet
```

## Usage

Once added to a project, you can generate a coverage report by running:

```bash
$ pub run duvet:duvet_cover
```

If you installed `duvet` globally, you can generate a report by running:

```bash
$ duvet_cover
```

`duvet` will then run your tests and collect coverage, outputting the report to a `coverage` directory. You can also pass the `--serve` option to automatically start a webserver to access the coverage reports.

## Example Report

You can view a sample coverage report for the `dart_style` package [here](https://duvet-sample-report.netlify.com).

## How it works

`duvet` works by running the `test` package against your project, and then using the `coverage` package to collect coverage information. It then assembles reports using [`hyper`](https://pub.dartlang.org/packages/hyper), and serves the reports using [`shelf`](https://pub.dartlang.org/packages/shelf).
