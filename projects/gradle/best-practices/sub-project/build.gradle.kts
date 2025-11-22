plugins {
    id("java-library")
    alias(libs.plugins.kotlin.jvm)
}

dependencies {
    // ✅ DO: Use single GAV string notation
    implementation("com.google.guava:guava:32.1.2-jre")

    // ✅ DO: Use version catalog references
    api(libs.slf4j.api)
    implementation(libs.bundles.jackson)

    // ✅ DO: Don't explicitly depend on Kotlin stdlib (auto-added)
    // The Kotlin plugin adds it automatically

    // ✅ DO: Declare dependencies once
    api(libs.commons.lang3)
    // ❌ DON'T: Duplicate in implementation

    // Test dependencies
    testImplementation(libs.bundles.junit)
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")

    // Exclude transitive dependencies when needed
    implementation("com.example:library:1.0") {
        exclude(group = "commons-logging", module = "commons-logging")
    }
}

// ✅ DO: Group and describe custom tasks
tasks.register("generateDocs") {
    group = "documentation"
    description = "Generates project documentation from source files"

    doLast {
        // Task action
    }
}

// ✅ DO: Use @CacheableTask annotation on task classes
@CacheableTask
abstract class ProcessingTask : DefaultTask() {
    @get:InputFile
    abstract val inputFile: RegularFileProperty

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun process() {
        // Processing logic
    }
}

// ✅ DO: Wire task dependencies through inputs/outputs, not dependsOn
tasks.register<ProcessingTask>("processData") {
    inputFile.set(tasks.named<GenerateTask>("generateData").flatMap { it.outputFile })
    outputFile.set(layout.buildDirectory.file("processed.txt"))
}

// ❌ DON'T: Use dependsOn for tasks with actions
// tasks.register<ProcessingTask>("processData") {
//     dependsOn("generateData")  // Avoid this
// }

// ✅ DO: Use lazy APIs, avoid calling .get() during configuration
val outputDir = layout.buildDirectory.dir("output")  // Lazy

tasks.register<Copy>("copyFiles") {
    from(outputDir)  // Lazy evaluation
    into(layout.buildDirectory.dir("final"))
}

// ❌ DON'T: Call .get() during configuration
// val outputDirFile = layout.buildDirectory.dir("output").get()  // Eager

// ✅ DO: Use map() to transform providers
val versionString = providers.gradleProperty("appVersion")
    .orElse("1.0.0")
    .map { "v$it" }

// ✅ DO: Pass configurations to tasks lazily
abstract class ClasspathPrinter : DefaultTask() {
    @get:InputFiles
    abstract val classpath: ConfigurableFileCollection

    @TaskAction
    fun print() {
        classpath.forEach { println(it) }
    }
}

tasks.register<ClasspathPrinter>("printClasspath") {
    // ✅ DO: Pass configuration lazily
    classpath.from(configurations.runtimeClasspath)

    // ❌ DON'T: Resolve during configuration
    // classpath.from(configurations.runtimeClasspath.get().resolve())
}

// ✅ DO: Avoid eager file collection APIs
tasks.register("analyzeFiles") {
    doLast {
        val files = configurations.runtimeClasspath.get()

        // ✅ DO: Use lazy methods
        files.forEach { println(it) }

        // ❌ DON'T: Use eager Collection methods
        // files.isEmpty()    // Triggers resolution
        // files.size         // Triggers resolution
        // files.toList()     // Triggers resolution
    }
}
