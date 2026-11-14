allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Keep playback and compression on one compatible Media3 release. 1.11
    // fixes transient audio underruns causing BUFFERING with a full source buffer
    // (androidx/media#3210). Apply to plugin compilation as well as app runtime.
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.media3") {
                useVersion("1.11.1")
                because("Fix audio underrun buffering and align shared Media3 modules")
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
