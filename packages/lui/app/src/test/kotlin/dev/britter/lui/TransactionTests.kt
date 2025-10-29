package dev.britter.lui

import org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test
import java.time.LocalDate

class TransactionTests {

    @Test
    fun `renders nicely`() {
        val transaction = Transaction(
            date = LocalDate.of(2025, 10, 25),
            description = "Some desc",
            credit = Statement("assets:bank:savings", "-500 EUR"),
            debit = Statement("expenses:equipment:fixed", "500 EUR")
        )

        assertThat(transaction.render()).isEqualTo(
            """
            2025-10-25 Some desc
                assets:bank:savings                       -500 EUR
                expenses:equipment:fixed                   500 EUR
            """.trimIndent()
        )
    }
}
