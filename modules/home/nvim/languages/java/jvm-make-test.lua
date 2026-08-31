-- Checks for jvm-make.lua. Run it from the repo root with
--   nvim --headless -l modules/home/nvim/languages/java/jvm-make-test.lua
-- or via `nix flake check`, which passes the module path as the first argument.
local M = dofile(arg[1] or "modules/home/nvim/languages/java/jvm-make.lua")

vim.cmd("filetype on")

-- Lays out a project and returns the path of a source file inside it.
local function project(files)
    local root = vim.fn.tempname()
    for _, f in ipairs(files) do
        vim.fn.mkdir(vim.fs.dirname(root .. "/" .. f), "p")
        vim.fn.writefile({}, root .. "/" .. f)
    end
    return root
end

local src = "app/src/main/java/com/foo/Bar.java"

-- Gradle: wrapper above the subproject, so the root search must walk past it.
local root = project({ "gradlew", "settings.gradle", "app/build.gradle", src })
vim.cmd.edit(root .. "/" .. src)
assert(vim.bo.makeprg == root .. "/gradlew --quiet $*", "gradle makeprg: " .. vim.bo.makeprg)
-- Kept for the parse checks at the end of this file, so jvm-make.lua does not
-- have to export it just to be testable.
local gradle_errorformat = vim.bo.errorformat
assert(gradle_errorformat:match("error: %%m"), "gradle errorformat: " .. gradle_errorformat)
-- $* is what makes `:make test` more than a hardcoded task.
assert(vim.fn.expand(vim.bo.makeprg:gsub("%$%*", "test")):match("gradlew %-%-quiet test$"))
vim.fn.delete(root, "rf")

-- Maven: the bundled compiler/maven.vim supplies the errorformat.
root = project({ "mvnw", "pom.xml", src })
vim.cmd.edit(root .. "/" .. src)
assert(vim.bo.makeprg == root .. "/mvnw --batch-mode $*", "maven makeprg: " .. vim.bo.makeprg)
assert(vim.b.current_compiler == "maven", "compiler maven was not applied")
assert(vim.bo.errorformat:match("Non%-parseable POM"), "maven errorformat: " .. vim.bo.errorformat)
vim.fn.delete(root, "rf")

-- No wrapper: fall back to the tool on PATH.
root = project({ "pom.xml", src })
vim.cmd.edit(root .. "/" .. src)
assert(vim.bo.makeprg == "mvn --batch-mode $*", "maven fallback: " .. vim.bo.makeprg)
vim.fn.delete(root, "rf")

-- Neither: no buffer-local override, so the global 'makeprg' still applies.
root = project({ src })
vim.cmd.edit(root .. "/" .. src)
assert(vim.bo.makeprg == "", "makeprg was changed for a non-JVM project: " .. vim.bo.makeprg)
vim.fn.delete(root, "rf")

-- A buffer with no file must not error.
vim.cmd("enew")
vim.bo.filetype = "java"

-- The Gradle errorformat, against output copied from real builds.
local log = {
    "> Task :app:compileJava FAILED",
    "/p/src/main/java/com/foo/Bar.java:12: error: cannot find symbol",
    "        foo.bar();",
    "           ^",
    "  symbol:   method bar()",
    "  location: variable foo of type Foo",
    "/p/src/main/java/com/foo/Bar.java:20: warning: [NullAway] passing @Nullable parameter 'x'",
    "    baz(x);",
    "       ^",
    "e: file:///p/build.gradle.kts:5:1: Unresolved reference: nosuch",
    "w: file:///p/src/main/kotlin/A.kt:9:13 Variable 'x' is never used",
    "e: /p/src/main/kotlin/B.kt: (28, 33): Unresolved reference: replaceFirstChar",
    "build file '/p/build.gradle': 12: unexpected token: } @ line 12, column 1.",
    "FAILURE: Build failed with an exception.",
    "* Try:",
    "> Run with --stacktrace option to get the stack trace.",
    "BUILD FAILED in 3s",
}

vim.fn.setqflist({}, " ", { lines = log, efm = gradle_errorformat })
local qf = vim.fn.getqflist()

local want = {
    { "/p/src/main/java/com/foo/Bar.java", 12, 12, "e", "cannot find symbol" },
    { "/p/src/main/java/com/foo/Bar.java", 20, 8, "w", "[NullAway] passing @Nullable parameter 'x'" },
    { "/p/build.gradle.kts", 5, 1, "e", "Unresolved reference: nosuch" },
    { "/p/src/main/kotlin/A.kt", 9, 13, "w", "Variable 'x' is never used" },
    { "/p/src/main/kotlin/B.kt", 28, 33, "e", "Unresolved reference: replaceFirstChar" },
    { "/p/build.gradle", 12, 1, "e", "unexpected token: }" },
}

assert(#qf == #want, ("parsed %d entries, want %d:\n%s"):format(#qf, #want, vim.inspect(qf)))
for i, w in ipairs(want) do
    local e = qf[i]
    -- %E/%W report an upper-case type, %t whatever the compiler printed.
    local got = { vim.fn.bufname(e.bufnr), e.lnum, e.col, e.type:lower(), vim.trim(e.text) }
    assert(vim.deep_equal(got, w), ("entry %d\n  got:  %s\n  want: %s"):format(i, vim.inspect(got), vim.inspect(w)))
end

print("all ok")
