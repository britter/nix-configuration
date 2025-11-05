plugins {
    alias(libs.plugins.kotlin.jvm)
    id("application")
}

dependencies {
    implementation(libs.jackson.dataformat.yaml)
    implementation(libs.jackson.module.kotlin)
    implementation(libs.javalin)
    implementation(libs.javalin.rendering)
    implementation(libs.jgit)
    implementation(libs.jte)

    runtimeOnly(libs.slf4j.simple)

    testImplementation(libs.junit.jupiter)
    testImplementation(libs.assertj)
    testImplementation(libs.selenide)
    testImplementation(libs.testcontainers.junitJupiter)
    testImplementation(libs.testcontainers.selenium)
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

    // configure podman as the docker backend for testcontainers
    val uid = providers.exec { commandLine("id", "-u") }.standardOutput.asText.get().trim()
    environment("DOCKER_HOST", "unix:///run/user/$uid/podman/podman.sock")
    environment("TESTCONTAINERS_RYUK_DISABLED", "true")
}
