-- Buffer-local 'makeprg'/'errorformat' for JVM projects, so `:make test` runs
-- `./gradlew test` or `./mvnw test` and the failures land in the quickfix list.
--
-- This mirrors nvim's own ftplugin/rust.vim, which picks between
-- compiler/cargo.vim and compiler/rustc.vim per buffer. Doing it per buffer
-- rather than once at startup means a Maven project and a Gradle project can be
-- open in the same session, and the root is resolved from the file being edited
-- instead of from the directory nvim happened to start in.
--
-- Maven reuses nvim's bundled compiler/maven.vim, which already parses POM
-- errors, javac output, SpotBugs findings and JUnit stack traces. Gradle needs a
-- hand-written errorformat because nvim ships no compiler/gradle.vim.

local M = {}

-- Only recognised lines become entries, so the quickfix list stays jumpable.
-- Patterns are tried in order, so the specific ones come before the general
-- ones and the catch-all discard comes last. Modelled on tfnico/vim-gradle.
local gradle_errorformat = table.concat({
    -- javac errors and warnings (the latter includes NullAway and anything else
    -- promoted by -Werror). javac follows each one with the offending source
    -- line and a caret; %p^ reads the column off that caret and ends the entry,
    -- and %-C swallows the source echo plus any "symbol:"/"location:" notes.
    "%E%f:%l: error: %m",
    "%W%f:%l: warning: %m",
    "%-Z%p^",
    "%-C%.%#",
    -- kotlinc, as of Kotlin 1.9, reports positions as a file:// URI. The message
    -- is separated from the column by a colon in the Gradle Kotlin DSL and by a
    -- space elsewhere, so both are listed. %t picks up e/w/i.
    "%t: file://%f:%l:%c: %m",
    "%t: file://%f:%l:%c %m",
    -- kotlinc before 1.9, still what Gradle plugins on older versions print.
    "%t: %f: (%l\\, %c): %m",
    -- Groovy build script compilation failures, which name the file in quotes:
    --   build file '/p/build.gradle': 12: unexpected token: } @ line 12, column 1.
    "%E%.%#'%f': %\\d%\\+: %m @ line %l\\, column %c.",
    "%E%f: %\\d%\\+: %m @ line %l\\, column %c.",
    -- Discard everything else
    "%-G%.%#",
}, ",")

-- The wrapper if there is one, else the tool from PATH, else nil. `markers` are
-- the files that identify a project without a wrapper; in a multi-project Gradle
-- build the wrapper lives above the subproject, so it gets its own search.
local function tool(dir, wrapper, bare, markers)
    local root = vim.fs.root(dir, wrapper)
    if root then
        return vim.fs.joinpath(root, wrapper)
    end
    if vim.fs.root(dir, markers) then
        return bare
    end
end

-- Returns "gradle" or "maven" plus the command to invoke, or nil for a file that
-- belongs to neither. Gradle wins a tie: polyglot repos that keep a pom.xml
-- around are usually built with Gradle.
function M.detect(dir)
    local gradle = tool(dir, "gradlew", "gradle", { "settings.gradle", "settings.gradle.kts" })
    if gradle then
        return "gradle", gradle
    end
    local maven = tool(dir, "mvnw", "mvn", { "pom.xml" })
    if maven then
        return "maven", maven
    end
end

function M.setup(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return
    end
    local build, cmd = M.detect(vim.fs.dirname(name))
    if build == "gradle" then
        vim.bo[bufnr].makeprg = cmd .. " --quiet $*"
        vim.bo[bufnr].errorformat = gradle_errorformat
    elseif build == "maven" then
        vim.api.nvim_buf_call(bufnr, function()
            -- `:compiler` without a bang sets b:makeprg and b:errorformat. Its
            -- makeprg has no $*, which would append arguments after ours.
            vim.cmd("compiler maven")
            vim.bo.makeprg = cmd .. " --batch-mode $*"
        end)
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "java", "kotlin", "groovy" },
    callback = function(args)
        M.setup(args.buf)
    end,
})

return M
