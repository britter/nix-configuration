---
name: programming.java.expert
description: |
  Working rules for Java projects: identify the build tool and load its
  specialized skill, modern Java coding practices, and where to look up JDK
  APIs, third-party Javadoc and dependency coordinates. Use whenever working
  on a Java, Kotlin or Groovy project.
---
# Java Projects

## Identify the build tool first

Before running anything, look for the build files at the repository root:

| File                                            | Build tool | Specialized skill                |
|-------------------------------------------------|------------|----------------------------------|
| `build.gradle(.kts)`, `settings.gradle(.kts)`   | Gradle     | `programming.java.gradle.expert` |
| `pom.xml`                                       | Maven      | `programming.java.maven.expert`  |

Load the matching skill and follow it for anything build-related. A repository
can contain both — a Maven build being migrated to Gradle, or independent
subprojects — in which case find out which one produces the artifact you care
about, and load both if the work spans them. If neither file is present, the
project is built some other way (Bazel, an IDE, a shell script); find out how
before inventing a command.

## Write modern Java

Match the surrounding code first: a codebase on Java 8 idioms does not want a
sealed interface hierarchy introduced in one file. Where the code is already
modern, or where you are writing something new, prefer these.

### Make nullability explicit

- Annotate packages as non-null by default with JSpecify's `@NullMarked` on
  the `package-info.java` (or on the module), then mark the exceptions with
  `@Nullable`. Marking every non-null parameter individually is noise; the
  default plus exceptions is the readable form, and it is what static
  analysers and Kotlin interop consume.
- Return `Optional<T>` instead of `null` from methods where absence is a
  normal outcome. Do not use `Optional` for fields, parameters, or collection
  elements — an empty collection already expresses absence.
- Never call `Optional.get()` without `isPresent()`; use `orElseThrow()`,
  `orElseGet()`, `map()`, or `ifPresent()` so the absent case is handled at
  the point it is known.
- `Objects.requireNonNull(x, "x")` in constructors for arguments that must not
  be null. Failing at construction beats a `NullPointerException` three calls
  later.

### Prefer the constructs the language now has

- `record` for data carriers. It gives you `equals`, `hashCode`, `toString`
  and immutability, and validation goes in a compact constructor.
- `sealed interface` plus a `switch` over the permitted types, using pattern
  matching, when modelling a closed set of alternatives. The compiler then
  proves the switch is exhaustive, which is the whole point.
- `switch` as an expression with `->` arms rather than statement `switch` with
  `break`.
- Text blocks (`"""`) for embedded SQL, JSON and multi-line messages.
- `java.time` for anything temporal. `Date`, `Calendar` and `SimpleDateFormat`
  are not to be used in new code.
- `List.of` / `Map.of` / `Set.of` and `stream().toList()` for immutable
  collections; `Collections.unmodifiableList` wrapping a mutable list is not
  the same thing.
- try-with-resources for anything `Closeable`. A `finally` block that closes a
  resource is a code smell in modern Java.
- `var` where the initialiser already names the type; not where it hides it.

### Design defaults

- Immutable by default: final fields, no setters, constructor takes everything
  the object needs. Mutability is a decision to justify, not a starting point.
- Constructor injection over field injection, and no framework annotations on
  fields. It keeps the class testable without a container.
- Program against interfaces at API boundaries, concrete types internally.
- Throw specific unchecked exceptions with a message naming the offending
  value; do not catch, log and rethrow the same exception at each layer.
- Keep `Stream` pipelines side-effect free — no `peek` for logic, no mutating
  a collection from `forEach` when a collector exists.
- Virtual threads (`Executors.newVirtualThreadPerTaskExecutor()`) for
  IO-bound concurrency on Java 21+, instead of a tuned fixed pool. Do not pool
  virtual threads.

## Look things up before guessing

- JDK API: https://docs.oracle.com/en/java/javase/21/docs/api/ — swap the
  version number for the project's actual release, since methods appear and
  deprecate between LTS versions.
- JDK release documentation, including preview features:
  https://docs.oracle.com/en/java/javase/21/
- Third-party API: https://javadoc.io/doc/<groupId>/<artifactId>/<version> —
  static HTML, available for anything published to Maven Central, and pinnable
  to the exact version the project depends on.
- Dependency coordinates and available versions:
  `https://search.maven.org/solrsearch/select?q=g:<group>+AND+a:<artifact>&core=gav&rows=20&wt=json`.
  Use this JSON API rather than https://central.sonatype.com, whose pages are
  a JavaScript shell that does not fetch usefully.
- Frameworks such as Spring Boot and Quarkus manage dependency versions
  through a BOM. Look up the version the framework manages before overriding
  one.
- JSpecify annotations and their exact semantics: https://jspecify.dev/docs/user-guide/
