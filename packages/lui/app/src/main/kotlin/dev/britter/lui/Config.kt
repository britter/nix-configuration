package dev.britter.lui

import java.net.URI
import java.nio.file.Path

data class Config(
    val repositoryURI: URI,
    val repositoryDirectory: Path = Path.of("/var/lib/lui/git-clone"),
    val journalFile: String
)
