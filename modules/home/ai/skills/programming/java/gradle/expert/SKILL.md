---
name: programming.java.gradle.expert
description: |
  Working rules for Gradle builds: use the wrapper, ask Gradle for its build
  model instead of guessing, and where dependency versions are declared. Use
  when building, testing, or changing dependencies in a project that has a
  build.gradle or settings.gradle file.
---
# Gradle

## Use the wrapper

Run `./gradlew`, never a `gradle` from `PATH`. The wrapper pins the Gradle
version the build was written against, and a different version produces
failures that look like code problems. It downloads its own distribution on
first use, so it works even where Gradle is not installed. If a project has no
wrapper, say so rather than substituting a system-wide version.

## Ask Gradle what it is doing

- `./gradlew tasks --all` and `./gradlew help --task <task>` — what exists and
  what a task accepts.
- `./gradlew :module:dependencies --configuration runtimeClasspath` — the
  resolved dependency graph for one configuration.
- `./gradlew :module:dependencyInsight --dependency <group:artifact>` — why a
  particular version won. This is the answer to nearly every version-conflict
  question.
- `./gradlew properties` — the effective project properties.
- `--stacktrace` and `--info` when a failure is unexplained; `--scan` for a
  shareable report when it does not reproduce locally. `--debug` is rarely
  readable.

Gradle prints whether a failure happened during configuration or during task
execution. Note which before reading further; it narrows the cause sharply.

## Dependency versions have one home

Find where versions are declared and change them there:

- A version catalog at `gradle/libs.versions.toml`, referenced as
  `libs.some.library`.
- A platform or BOM applied with `platform(...)`.
- Convention plugins under `buildSrc/` or an included `build-logic` build. In
  a project that has these, per-module build files are usually the wrong place
  for a change.

Adding a hard-coded version alongside an existing catalog or BOM entry is a
defect even when it builds.

## Test results live in the reports

The console output is truncated. Read
`build/reports/tests/test/index.html` or the XML in
`build/test-results/test/` for the real assertion and stack trace. Iterate on
a single test with
`./gradlew test --tests 'com.example.SomeTest.someMethod'`.

## Documentation

- User guide: https://docs.gradle.org/current/userguide/userguide.html
- DSL reference: https://docs.gradle.org/current/dsl/
- Kotlin DSL API: https://docs.gradle.org/current/kotlin-dsl/

Pin the version in the URL (`https://docs.gradle.org/8.14/...`) when the
project is not on the current release; the DSL moves between versions.
