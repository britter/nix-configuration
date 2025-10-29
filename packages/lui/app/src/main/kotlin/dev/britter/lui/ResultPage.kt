package dev.britter.lui

data class ResultPage(
    @JvmField val commitMsg: String,
    @JvmField val transaction: Transaction
)
