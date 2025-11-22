# Custom Task with Proper Annotations

```kotlin
import org.gradle.api.tasks.*
import org.gradle.work.DisableCachingByDefault

// For cacheable tasks
@CacheableTask
abstract class ProcessingTask : DefaultTask() {

    @get:InputFile
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val inputFile: RegularFileProperty

    @get:Input
    abstract val configuration: Property<String>

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun process() {
        val input = inputFile.get().asFile.readText()
        val config = configuration.get()

        // Do processing
        val result = processInput(input, config)

        outputFile.get().asFile.writeText(result)
    }

    private fun processInput(input: String, config: String): String {
        return "$config: $input"
    }
}

// For non-cacheable tasks (document why)
@DisableCachingByDefault(because = "Outputs are non-deterministic")
abstract class TimestampTask : DefaultTask() {

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun generate() {
        outputFile.get().asFile.writeText(System.currentTimeMillis().toString())
    }
}
```

---

# Task Dependency Through Input/Output Wiring

```kotlin
// Producer task
abstract class GenerateTask : DefaultTask() {
    @get:OutputFile
    abstract val generatedFile: RegularFileProperty

    @TaskAction
    fun generate() {
        generatedFile.get().asFile.writeText("Generated content")
    }
}

// Consumer task
abstract class ConsumeTask : DefaultTask() {
    @get:InputFile
    abstract val inputFile: RegularFileProperty

    @TaskAction
    fun consume() {
        println(inputFile.get().asFile.readText())
    }
}

// Registration
tasks.register<GenerateTask>("generate") {
    generatedFile.set(layout.buildDirectory.file("generated.txt"))
}

tasks.register<ConsumeTask>("consume") {
    // ✅ DO: Wire through input/output
    inputFile.set(tasks.named<GenerateTask>("generate").flatMap { it.generatedFile })

    // ❌ DON'T: Use dependsOn
    // dependsOn("generate")
}
```

---

# Don't Use Internal APIs

```kotlin
// ❌ DON'T
import org.gradle.api.internal.attributes.AttributeContainerInternal

configurations.create("bad") {
    val map = (attributes as AttributeContainerInternal).asMap()
}

// ✅ DO: Use public APIs only
configurations.create("good") {
    val map = attributes.keySet().associate {
        Attribute.of(it.name, it.type) to attributes.getAttribute(it)
    }
}
```

---

# Don't Use Named Argument Notation for Dependencies

```kotlin
// ❌ DON'T (deprecated in Gradle 10)
dependencies {
    implementation(group = "com.google.guava", name = "guava", version = "32.1.2-jre")
}

// ✅ DO: Use single GAV string
dependencies {
    implementation("com.google.guava:guava:32.1.2-jre")
}
```

---

# Don't Perform Expensive Work During Configuration

```kotlin
// ❌ DON'T
fun expensiveComputation(): String {
    Thread.sleep(5000)
    return "result"
}

tasks.register("myTask") {
    val result = expensiveComputation()  // Runs during configuration!
    doLast {
        println(result)
    }
}

// ✅ DO: Move to task action
tasks.register("myTask") {
    doLast {
        val result = expensiveComputation()  // Runs during execution
        println(result)
    }
}
```

---

# Don't Call .get() on Providers During Configuration

```kotlin
// ❌ DON'T
val version = providers.gradleProperty("version")
tasks.register("bad") {
    val v = version.get()  // Eager evaluation
    doLast {
        println("Version: $v")
    }
}

// ✅ DO: Use map() or pass provider directly
tasks.register("good") {
    val v = version.map { "Version: $it" }  // Lazy
    doLast {
        println(v.get())
    }
}
```

---

# Don't Resolve Configurations During Configuration

```kotlin
// ❌ DON'T
tasks.register<Copy>("badCopy") {
    val files = configurations.runtimeClasspath.get().resolve()  // Resolves early!
    from(files)
}

// ✅ DO: Pass configuration directly
tasks.register<Copy>("goodCopy") {
    from(configurations.runtimeClasspath)  // Lazy resolution
}
```

---
