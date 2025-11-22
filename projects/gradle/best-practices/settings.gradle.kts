// Centralize repository configuration here, not in build files.

// Plugin management for all projects
pluginManagement {

    // Repositories for resolving plugins
    repositories {
        // Order matters: Gradle will search repositories in order
        gradlePluginPortal() // 1. Gradle Plugin Portal
        mavenCentral() // 2. Central repository
        google() // 3. Google repository
        // etc.
    }

}

// Dependency resolution management for all projects
dependencyResolutionManagement {

    // Prevents subprojects from declaring their own repositories
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)

    // Repositories for resolving dependencies
    repositories {
        // Order matters: Gradle will search repositories in order
        mavenCentral() // 1. Central repository
        privateMaven("https://my.company.repo/maven2") { // 2. Private company repository
            name = "CompanyRepo"
            credentials {
                username = findProperty("repoUser") as String? ?: System.getenv("REPO_USER")
                password = findProperty("repoPassword") as String? ?: System.getenv("REPO_PASSWORD")
            }
        }
        google() // 3. Google repository
        jcenter() // 4. JCenter (deprecated, use only if necessary)
        mavenLocal() // 5. Local Maven repository
        // etc.

        // Use content filtering for multiple repositories
        google {
            content {
                includeGroupByRegex("androidx.*")
                includeGroup("com.google.android.material")
                includeGroup("com.google.gms")
            }
        }

        // Exclusive content filtering (recommended)
        exclusiveContent {
            forRepository {
                maven("https://repo.spring.io/milestone")
            }
            filter {
                includeGroup("org.springframework")
            }
        }
    }

}

// Set the root project name
rootProject.name = "my-project"
// Include subprojects
include("app", "lib")
