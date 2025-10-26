plugins {
    alias(libs.plugins.kotlin.jvm)
    id("application")
}

dependencies {
    implementation(libs.jgit)

    testImplementation(libs.junit.jupiter)
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

application {
    mainClass = "dev.britter.lui.AppKt"
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}
