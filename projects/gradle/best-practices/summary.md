# Gradle Best Practices — Do & Don’t

| **Category**             | **Do**                                    | **Don't ❌**                       |
| ------------------------ | ----------------------------------------- | ---------------------------------- |
| **DSL**                  | Use Kotlin DSL (`build.gradle.kts`)       | Use Groovy DSL for new builds      |
| **Plugins**              | Use `plugins {}` block                    | Use `apply(plugin = …)`            |
| **Versions**             | Use version catalogs                      | Hardcode versions in build files   |
| **Repositories**         | Declare in `settings.gradle.kts`          | Declare in each `build.gradle.kts` |
| **Dependencies**         | Use GAV string `"group:artifact:version"` | Use named arguments (deprecated)   |
| **Repository Filtering** | Use content filtering                     | Query all repos for all deps       |
| **Task Dependencies**    | Wire through inputs/outputs               | Use `dependsOn` for action tasks   |
| **Caching**              | Annotate task class `@CacheableTask`      | Use `cacheIf {}` on instances      |
| **Providers**            | Use `map()`, `flatMap()`                  | Call `.get()` during configuration |
| **Configurations**       | Pass to tasks lazily                      | Resolve with `.get().resolve()`    |
| **File Collections**     | Use lazy APIs                             | Use `.isEmpty()`, `.size()`        |
| **Properties**           | Set in `gradle.properties`                | Pass via command line              |
| **Encoding**             | Set UTF-8 in `gradle.properties`          | Rely on system defaults            |
| **Gradle Version**       | Use latest minor version                  | Stay on old versions               |
| **Wrapper Security**     | Set `distributionSha256Sum`               | Skip checksum validation           |
| **Custom Tasks**         | Set `group` and `description`             | Leave them unset                   |
| **APIs**                 | Use public APIs only                      | Use internal packages              |
