https://docs.gradle.org/current/userguide/java_plugin.html

```
plugins {
    java
}
```

- Task https://docs.gradle.org/current/userguide/java_plugin.html#sec:java_tasks
- SourceSet Tasks https://docs.gradle.org/current/userguide/java_plugin.html#java_source_set_tasks
- Lifecycle Tasks https://docs.gradle.org/current/userguide/java_plugin.html#lifecycle_tasks

---

# Project layout

```
src/main/java
Production Java source.

src/main/resources
Production resources, such as XML and properties files.

src/test/java
Test Java source.

src/test/resources
Test resources.

src/sourceSet/java
Java source for the source set named sourceSet.

src/sourceSet/resources
Resources for the source set named sourceSet.

```

## Custom Java source layout

```
sourceSets {
    main {
        java {
            setSrcDirs(listOf("src/java"))
        }
        resources {
            setSrcDirs(listOf("src/resources"))
        }
    }
}
```
