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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround: some older plugins (e.g. image_gallery_saver 2.0.3) miss the required
// `namespace` property with AGP 8+. Inject a namespace so the build won't fail.
subprojects {
    if (name == "image_gallery_saver") {
        pluginManager.withPlugin("com.android.library") {
            extensions.findByName("android")?.let { ext ->
                // Use reflection-safe set if the property exists
                try {
                    val method = ext::class.members.firstOrNull { it.name == "setNamespace" }
                    if (method != null) {
                        method.call(ext, "io.flutter.plugins.image_gallery_saver")
                    } else {
                        // Fallback: try property access
                        ext.javaClass.getMethod("setNamespace", String::class.java)
                            .invoke(ext, "io.flutter.plugins.image_gallery_saver")
                    }
                } catch (_: Throwable) {
                    println("[build.gradle.kts] Warning: failed to set namespace for image_gallery_saver")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
