package dev.britter.lui

import com.fasterxml.jackson.dataformat.yaml.YAMLMapper
import com.fasterxml.jackson.module.kotlin.KotlinModule
import io.javalin.Javalin
import io.javalin.rendering.template.JavalinJte
import org.eclipse.jgit.api.CloneCommand
import org.eclipse.jgit.api.Git
import java.nio.file.Files
import java.nio.file.Path
import java.time.LocalDate

class App(val config: Config) {

    fun run() {
        prepare()
        startWebservice()
    }

    private fun startWebservice() {
        val app = Javalin.create {
            it.fileRenderer(JavalinJte())
        }.start(7000)

        app.get("/") { ctx -> ctx.render("home.jte") }
        app.post("/new-transaction") { ctx ->
            val commitMsg = ctx.formParam("commit-msg")!!
            val transaction = Transaction(
                date = LocalDate.parse(ctx.formParam("date")!!),
                description = ctx.formParam("description")!!,
                credit = Statement(ctx.formParam("account-1")!!, ctx.formParam("amount-1")!!),
                debit = Statement(ctx.formParam("account-2")!!, ctx.formParam("amount-2")!!)
            )
            ctx.render("result.jte", mapOf("page" to ResultPage(commitMsg, transaction)))
        }
    }


    private fun prepare(): Git = if (Files.exists(config.repositoryDirectory))
        Git.open(config.repositoryDirectory.toFile()).also {
            it.pull().call()
        }
    else
        CloneCommand().setURI(config.repositoryURI.toString()).setDirectory(config.repositoryDirectory.toFile())
            .call()
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
