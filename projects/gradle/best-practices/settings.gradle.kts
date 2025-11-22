// Centralize repository configuration here, not in build files.

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)

    repositories {
        mavenCentral()

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

rootProject.name = "my-project"
include("app", "lib")
