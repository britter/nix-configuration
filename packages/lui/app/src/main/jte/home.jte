<h2>New Transaction:</h2>
<form method="post" action="/new-transaction">
    <label>
        Date
        <input name="date" type="date" required>
    </label>
    <br>
    <label>
        Description
        <input name="description" type="text" required>
    </label>
    <br>
    <label>
        Account 1
        <input name="account-1" type="text" required>
    </label>
    <br>
    <label>
        Amount 1
        <input name="amount-1" type="text" required>
    </label>
    <br>
    <label>
        Account 2
        <input name="account-2" type="text" required>
    </label>
    <br>
    <label>
        Amount 2
        <input name="amount-2" type="text" required>
    </label>
    <br>
    <label>
        Commit Message
        <input name="commit-msg" type="text" required>
    </label>
    <br>
    <button id="submit-button">Submit</button>
</form>
