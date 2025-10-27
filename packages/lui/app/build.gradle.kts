plugins {
    alias(libs.plugins.kotlin.jvm)
    id("application")
}

dependencies {
    implementation(libs.jackson.dataformat.yaml)
    implementation(libs.jackson.module.kotlin)
    implementation(libs.jgit)

    testImplementation(libs.junit.jupiter)
    testImplementation(libs.assertj)
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
