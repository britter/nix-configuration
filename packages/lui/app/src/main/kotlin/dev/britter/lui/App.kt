package dev.britter.lui

import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.PersonIdent
import java.net.URI
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption

class App(val repoURI: URI, val repoDir: Path, val journalFile: String) {

    fun run() {
        val git = if (Files.exists(repoDir))
            Git.open(repoDir.resolve(".git").toFile()).also {
                it.pull().call()
            }
        else
            CloneCommand().setURI(repoURI.toString()).setDirectory(repoDir.toFile()).call()

        Files.writeString(
            repoDir.resolve(journalFile),
            "Hello world!",
            StandardOpenOption.CREATE,
            StandardOpenOption.APPEND
        )

        git.add().addFilepattern(journalFile).call()
        git.commit().also {
            it.author = PersonIdent("lui", "lui@britter.dev")
            it.message = "Update journal"
        }.call()
    }
}

fun main(args: Array<String>) {
    require(args.size == 4 && args[0] == "--repository-uri" && args[2] == "--journal-file") {
        "Usage: lui --repository-uri https://git.example.com --journal-file 2025.journal"
    }
    val repoUri = URI.create(args[1])
    val repoDir = Path.of("/var/lib/lui/data/git-clone").also {
        Files.createDirectories(it.parent)
    }
    val journalFile = args[3]

    App(repoUri, repoDir, journalFile).run()
}
