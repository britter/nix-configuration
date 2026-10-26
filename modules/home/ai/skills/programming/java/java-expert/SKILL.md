---
name: java-expert
description: |
  Working rules for Java projects. Identify the build tool and load its
  specialized skill. Apply modern Java coding practices. Know where to look
  up JDK APIs, third-party Javadoc and dependency coordinates. Use whenever
  working on a Java, Kotlin or Groovy project.
---
# Java Projects

## Identify the build tool first

Before running anything, look for the build files at the repository root:

| File                                            | Build tool | Specialized skill                |
|-------------------------------------------------|------------|----------------------------------|
| `build.gradle(.kts)`, `settings.gradle(.kts)`   | Gradle     | `java-gradle`                    |
| `pom.xml`                                       | Maven      | `java-maven`                     |

Load the matching skill and follow it for anything build-related. A repository
can contain both build files — a Maven build being migrated to Gradle, or
independent subprojects. Then find out which one produces the artifact you
care about, and load both skills if the work spans them. If neither file is
present, the project uses another build method (Bazel, an IDE, a shell
script). Find out how before inventing a command.

## Write modern Java

Match the surrounding code first: a codebase on Java 8 idioms does not want a
sealed interface hierarchy introduced in one file. Where the code is already
modern, or where you are writing something new, prefer these.

### Make nullability explicit

- Annotate packages as non-null by default with JSpecify's `@NullMarked` on
  the `package-info.java` (or on the module), then mark the exceptions with
  `@Nullable`. Marking every non-null parameter individually is noise. The
  default plus exceptions is the readable form. It is also what static
  analysers and Kotlin interop consume.
- Return `Optional<T>` instead of `null` from methods where absence is a
  normal outcome. Do not use `Optional` for fields, parameters, or collection
  elements — an empty collection already expresses absence.
- Never call `Optional.get()` without `isPresent()`. Use `orElseThrow()`,
  `orElseGet()`, `map()`, or `ifPresent()` to handle the absent case at the
  point where the code knows it.
- Put `Objects.requireNonNull(x, "x")` in constructors for arguments that must
  not be null. Failing at construction beats a `NullPointerException` three
  calls later.

### Prefer the constructs the language now has

- `record` for data carriers. It gives you `equals`, `hashCode`, `toString`
  and immutability, and validation goes in a compact constructor.
- `sealed interface` plus a `switch` over the permitted types, using pattern
  matching, when modelling a closed set of alternatives. The compiler then
  proves the switch is exhaustive, which is the whole point.
- Prefer `switch` as an expression with `->` arms over statement `switch`
  with `break`.
- Use text blocks (`"""`) for embedded SQL, JSON and multi-line messages.
- Use `java.time` for anything temporal. Do not use `Date`, `Calendar`, or
  `SimpleDateFormat` in new code.
- Use `List.of` / `Map.of` / `Set.of` and `stream().toList()` for immutable
  collections. `Collections.unmodifiableList` wrapping a mutable list is not
  the same thing.
- Use try-with-resources for anything `Closeable`. A `finally` block that
  closes a resource is a code smell in modern Java.
- Use `var` where the initialiser already names the type. Do not use it
  where it hides the type.

### Design defaults

- Default to immutability: final fields, no setters, and a constructor that
  takes everything the object needs. Mutability is a decision to justify, not
  a starting point.
- Prefer constructor injection over field injection, and put no framework
  annotations on fields. It keeps the class testable without a container.
- Program against interfaces at API boundaries, concrete types internally.
- Throw specific unchecked exceptions with a message naming the offending
  value. Do not catch, log and rethrow the same exception at each layer.
- Keep `Stream` pipelines side-effect free. Do not use `peek` for logic, and
  do not mutate a collection from `forEach` when a collector exists.
- Use virtual threads (`Executors.newVirtualThreadPerTaskExecutor()`) for
  IO-bound concurrency on Java 21+, instead of a tuned fixed pool. Do not pool
  virtual threads.

## Look things up before guessing

- JDK API: https://docs.oracle.com/en/java/javase/21/docs/api/ — swap the
  version number for the project's actual release, since methods appear and
  deprecate between LTS versions.
- JDK release documentation, including preview features:
  https://docs.oracle.com/en/java/javase/21/
- Third-party API: https://javadoc.io/doc/<groupId>/<artifactId>/<version> —
  The pages are static HTML. They exist for anything published to Maven
  Central. You can pin them to the exact version the project depends on.- Dependency coordinates and available versions:
  `https://search.maven.org/solrsearch/select?q=g:<group>+AND+a:<artifact>&core=gav&rows=20&wt=json`.
  Use this JSON API rather than https://central.sonatype.com, whose pages are
  a JavaScript shell that does not fetch usefully.
- Frameworks such as Spring Boot and Quarkus manage dependency versions
  through a BOM. Look up the version the framework manages before overriding
  one.
- JSpecify annotations and their exact semantics: https://jspecify.dev/docs/user-guide/
