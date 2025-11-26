plugins {
    java // turns a project into a standard Java module
    // adding tasks to compile Java source code, run tests, create JARs, etc.
    // defining source directories like src/main/java and src/test/java
    // create dependency configurations like implementation, api, testImplementation, etc.

    java-library // extends 'java' plugin for building Java libraries
    // adds features for consumers of the library, like api configuration

    alias(...) apply false // Placeholders for plugin aliases from version catalog

    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.versions) apply false
}

allprojects { // Configuration common to all projects in the build
    group = "com.example"
    version = "1.0.0-SNAPSHOT"
}

subprojects { // Configuration common to all subprojects
    apply(plugin = "java")

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    // Configure Java compilation tasks
    tasks.withType<JavaCompile> {
        sourceCompatibility = libs.versions.java.get()
        targetCompatibility = libs.versions.java.get()
        options.encoding = "UTF-8"
    }

    // Configure test tasks to use JUnit Platform
    tasks.withType<Test> {
        useJUnitPlatform()
    }
}
