// Main build configuration for ShopTrack Flutter application
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define custom build directory to avoid conflicts
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Set build directories for all subprojects
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure proper project evaluation order
subprojects {
    project.evaluationDependsOn(":app")
}

// Register clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
