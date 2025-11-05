package dev.britter.lui

import com.codeborne.selenide.Condition.visible
import com.codeborne.selenide.Configuration
import com.codeborne.selenide.Selenide.`$`
import com.codeborne.selenide.Selenide.open
import org.assertj.core.api.Assertions.assertThat
import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.PersonIdent
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import org.openqa.selenium.By
import org.testcontainers.containers.wait.strategy.Wait
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import org.testcontainers.selenium.BrowserWebDriverContainer
import java.nio.file.Path
import kotlin.io.path.absolutePathString
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

@Testcontainers
class End2EndTests {

    @field:Container
    val firefox: BrowserWebDriverContainer = BrowserWebDriverContainer("selenium/standalone-firefox:141.0-20251025")
        .waitingFor(Wait.forHttp("/wd/hub/status").forStatusCode(200)).withExposedPorts(4444)

    @field:TempDir
    lateinit var tempDir: Path

    @Test
    fun `commits transations to the journal file`() {
        val origin = tempDir.resolve("origin").also { it.createDirectories() }
        Git.init().also {
            it.setDirectory(origin.toFile())
            it.setBare(true)
        }.call()

        val controlRepo = tempDir.resolve("control").also { it.createDirectories() }
        val git =
            CloneCommand().also { it.setDirectory(controlRepo.toFile()).setURI(origin.absolutePathString()) }.call()
        val journalFile = controlRepo.resolve("my.journal").also {
            it.writeText("")
        }
        git.add().also { it.isAll = true }.call()
        git.commit().also {
            it.author = PersonIdent("John Doe", "john@example.com")
            it.message = "Initial commit"
            it.setSign(false)
        }.call()
        git.push().call()

        val config = Config(origin.toUri(), tempDir.resolve("lui-clone"), "my.journal", "John Doe", "john@example.com")
        App(config).run()

        Configuration.baseUrl = "http://host.containers.internal:7000"
        Configuration.remote = "http://${firefox.host}:${firefox.getMappedPort(4444)}/wd/hub"
        Configuration.browser = "firefox";
        Configuration.browserCapabilities.run {
            setCapability("se:biDiEnabled", false)
            setCapability("webSocketUrl", false)
        }

        System.setProperty("selenide.browserLogs", "false")
        System.setProperty("selenide.headless", "true")

// These are internal but respected by Selenium 4.38+
        System.setProperty("webdriver.firefox.enableBidi", "false")
        System.setProperty("webdriver.chrome.enableBidi", "false")


        // fill form, click submit
        open("/")
        `$`(By.name("date")).`val`("2025-10-31")
        `$`(By.name("description")).`val`("Halloween transaction")
        `$`(By.name("account-1")).`val`("assets:bank:savings")
        `$`(By.name("amount-1")).`val`("-10 $")
        `$`(By.name("account-2")).`val`("expenses:groceries")
        `$`(By.name("amount-2")).`val`("10 $")
        `$`(By.name("commit-msg")).`val`("First transaction!")
        `$`(By.id("submit-button")).click()

        // wait for result page to show up
        `$`(By.id("transaction-summary")).shouldBe(visible)

        git.pull().call()
        assertThat(journalFile).content()
            .contains("2025-10-31 Halloween transaction")
            .contains("assets:bank:savings").contains("-10 $")
            .contains("expenses:groceries").contains("10 $")
    }
}
