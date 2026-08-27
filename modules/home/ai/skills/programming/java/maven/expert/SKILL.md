---
name: programming.java.maven.expert
description: |
  Working rules for Maven builds: use the wrapper, ask Maven for its effective
  build model instead of guessing, and where dependency versions are declared.
  Use when building, testing, or changing dependencies in a project that has a
  pom.xml.
---
# Maven

## Use the wrapper

Run `./mvnw`, never an `mvn` from `PATH`. The wrapper pins the Maven version
the build was written against and downloads it on first use, so it works even
where Maven is not installed. If a project has no wrapper, say so rather than
substituting a system-wide version.

## Ask Maven what it is doing

- `./mvnw help:effective-pom` — the POM after inheritance, profiles and
  property interpolation. This, not the file on disk, is what actually runs.
- `./mvnw dependency:tree -Dverbose` — the resolved graph, including the
  entries omitted for conflict, which is where version fights are visible.
- `./mvnw help:describe -Dplugin=<groupId:artifactId> -Ddetail` — a plugin's
  real goals and parameters.
- `./mvnw help:active-profiles` — which profiles are on. A frequent cause of
  "works in CI, fails locally".
- `-o` for offline, `-U` to force snapshot updates, `-X` for debug output.

## Dependency versions have one home

Versions belong in the parent POM's `<dependencyManagement>` block, usually
via a `<properties>` constant. Child modules declare the dependency without a
`<version>`. Adding a version to a child module that inherits one is a defect
even when it builds.

## Test results live in the reports

Read `target/surefire-reports/` (or `target/failsafe-reports/` for integration
tests) for the real assertion and stack trace rather than trusting the console
summary. Iterate on a single test with
`./mvnw test -Dtest=SomeTest#someMethod`.

## Documentation

- POM reference and the build lifecycle:
  https://maven.apache.org/ref/current/
- Bundled plugins: https://maven.apache.org/plugins/

Plugin documentation is generated per version — check the version pinned in
the POM before reading the current page.
