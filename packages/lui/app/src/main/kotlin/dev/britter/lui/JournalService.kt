package dev.britter.lui

import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.PersonIdent
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.StandardOpenOption

class JournalService(private val git: Git, private val config: Config) {
    private val journalFile =
        git.repository.directory.toPath().parent.resolve(config.journalFile)

    init {
        require(Files.isRegularFile(journalFile)) {
            "Journal file $journalFile does not exist"
        }
    }

    fun commit(transaction: Transaction, commitMsg: String): Unit {
        git.pull().call()

        Files.writeString(
            journalFile,
            "\n\n${transaction.render()}\n",
            StandardCharsets.UTF_8,
            StandardOpenOption.APPEND
        )

        git.add().addFilepattern(config.journalFile).call()
        git.commit().also {
            it.author = PersonIdent(config.gitUser, config.gitEmail)
            it.message = commitMsg
            it.setSign(false)
        }.call()

        git.push().call()
    }
}
