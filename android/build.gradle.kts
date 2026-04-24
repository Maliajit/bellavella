allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directory to project root as requested by user
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

println("ROOT build.gradle.kts: configuring projects...")

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val namespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    val getNamespaceMethod = android.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespaceMethod.invoke(android)

                    if (currentNamespace == null || (currentNamespace as String).isEmpty()) {
                        val newNamespace = "com.example.${project.name.replace("-", ".").replace("_", ".")}"
                        namespaceMethod.invoke(android, newNamespace)
                        println("REPAIR: Injected namespace '$newNamespace' for project '${project.name}'")
                    }
                } catch (e: Exception) {
                    try {
                        val field = android.javaClass.getDeclaredField("namespace")
                        field.isAccessible = true
                        if (field.get(android) == null) {
                            val newNamespace = "com.example.${project.name.replace("-", ".").replace("_", ".")}"
                            field.set(android, newNamespace)
                            println("REPAIR: Injected namespace '$newNamespace' (field) for project '${project.name}'")
                        }
                    } catch (e2: Exception) {
                    }
                }

                android.javaClass.getMethod("getCompileOptions").invoke(android).let { options ->
                    options.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(options, JavaVersion.VERSION_21)
                    options.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(options, JavaVersion.VERSION_21)
                }

                try {
                    android.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(android, 36)
                } catch (e: Exception) {
                    // Ignore if method not found (unlikely for android projects)
                }
            }
        }

        // Third-party Android library lint can fail on bundled Kotlin metadata
        // even when the app itself compiles. Keep app lint enabled, but avoid
        // plugin subprojects blocking release builds on their own lint tasks.
        if (project.plugins.hasPlugin("com.android.library")) {
            project.tasks.matching {
                it.name == "lintVitalAnalyzeRelease" ||
                    it.name == "lintVitalReportRelease" ||
                    it.name == "lintVitalRelease"
            }.configureEach {
                enabled = false
            }
        }

        project.extensions.findByType(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java)?.compilerOptions?.jvmTarget?.set(
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
        )
    }
}
