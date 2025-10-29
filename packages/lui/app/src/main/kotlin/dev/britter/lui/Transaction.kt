package dev.britter.lui

import java.time.LocalDate

data class Transaction(
    val date: LocalDate,
    val description: String,
    val debit: Statement,
    val credit: Statement,
) {
    init {
        debit.isWithdraw
        credit.isDeposit
    }

    fun render(): String =
        """
        $date $description
            ${credit.render()}
            ${debit.render()}
        """.trimIndent()
}

data class Statement(val account: String, val amount: String) {
    val isWithdraw: Boolean = amount.startsWith("-")
    val isDeposit: Boolean = !isWithdraw

    fun render(): String = "$account${padding()}$amount"

    private fun padding() = " ".repeat(LINE_WIDTH - account.length - amount.length)

    companion object {
        const val LINE_WIDTH = 50
    }
}
