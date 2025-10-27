package dev.britter.lui

import com.fasterxml.jackson.dataformat.yaml.YAMLMapper
import com.fasterxml.jackson.module.kotlin.KotlinModule
import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.lib.PersonIdent
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption

class App(val config: Config) {

    fun run() {
        val git = if (Files.exists(config.repositoryDirectory))
            Git.open(config.repositoryDirectory.toFile()).also {
                it.pull().call()
            }
        else
            CloneCommand().setURI(config.repositoryURI.toString()).setDirectory(config.repositoryDirectory.toFile())
                .call()

        val transaction = """
            2025-10-31 Halloween transaction
                assets:bank:savings                -10 $
                expenses:groceries                  10 $
        """.trimIndent()
        Files.writeString(
            config.repositoryDirectory.resolve(config.journalFile),
            "\n\n$transaction\n",
            StandardOpenOption.CREATE,
            StandardOpenOption.APPEND
        )

        git.add().addFilepattern(config.journalFile).call()
        git.commit().also {
            it.author = PersonIdent("lui", "lui@britter.dev")
            it.message = "Update journal"
            it.setSign(false)
        }.call()

        git.push().call()
    }
}

fun main(args: Array<String>) {
    val configFile = if (args.size == 2) {
        Path.of(args[1])
    } else {
        Path.of("/var/lib/lui/config.yaml")
    }
    val mapper = YAMLMapper().registerModule(KotlinModule.Builder().build())
    val config = mapper.readValue(configFile.toFile(), Config::class.java)
    App(config).run()
}
