package dev.britter.lui

import org.assertj.core.api.Assertions.assertThat
import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.PersonIdent
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.io.path.absolutePathString
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

class End2EndTests {

    @field:TempDir
    lateinit var tempDir: Path

    @Test
    fun `test lui end 2 end`() {
        val origin = tempDir.resolve("origin").also { it.createDirectories() }
        Git.init().also { it.setDirectory(origin.toFile())
        it.setBare(true) }.call()

        val controlRepo = tempDir.resolve("control").also { it.createDirectories() }
        val git = CloneCommand().also { it.setDirectory(controlRepo.toFile()).setURI(origin.absolutePathString()) }.call()
        val journalFile = controlRepo.resolve("my.journal").also {
            it.writeText("""
                2025-10-20 Demo transaction
                    assets:bank:savings                -500 $
                    expenses:equipment                  500 $
            """.trimIndent())
        }
        git.add().also { it.isAll = true }.call()
        git.commit().also {
            it.author = PersonIdent("John Doe", "john@example.com")
            it.message = "Initial commit"
            it.setSign(false)
        }.call()
        git.push().call()

        val config = Config(origin.toUri(), tempDir.resolve("lui-clone"), "my.journal")
        App(config).run()

        git.pull().call()
        assertThat(journalFile).content()
            .contains("2025-10-31 Halloween transaction")
            .contains("assets:bank:savings").contains("-10 $")
            .contains("expenses:groceries").contains("10 $")
    }
}