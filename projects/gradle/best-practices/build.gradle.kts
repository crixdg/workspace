plugins {
    // Apply plugins using the plugins block (not apply())
    id("java")
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.versions) apply false
}

allprojects {
    group = "com.example"
    version = "1.0.0-SNAPSHOT"
}

subprojects {
    apply(plugin = "java")

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    tasks.withType<JavaCompile> {
        options.encoding = "UTF-8"
    }

    tasks.withType<Test> {
        useJUnitPlatform()
    }
}
