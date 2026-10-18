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

subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val methods = android.javaClass.methods
            val setter = methods.firstOrNull { m ->
                (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion") &&
                    m.parameterTypes.size == 1
            }
            if (setter != null) {
                val param = setter.parameterTypes[0]
                val arg: Any = when (param) {
                    Int::class.javaPrimitiveType,
                    Int::class.javaObjectType,
                -> 36
                    String::class.java -> "36"
                    else -> return@afterEvaluate
                }
                setter.invoke(android, arg)
            }
        } catch (_: Throwable) {
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

allprojects {
    tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        this.compilerOptions.languageVersion.set(
            org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0,
        )
        this.compilerOptions.jvmTarget.set(
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
