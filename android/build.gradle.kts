import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Remove or comment out this block - it forces evaluation too early
// subprojects {
//     project.evaluationDependsOn(":app")
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate {
        val hasAndroidPlugin =
            plugins.hasPlugin("com.android.application") ||
                plugins.hasPlugin("com.android.library")

        if (hasAndroidPlugin) {
            extensions.findByType(BaseExtension::class.java)?.apply {
                compileSdkVersion(36)
                buildToolsVersion("36.0.0")
            }
        }
    }
}