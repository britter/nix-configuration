-- Checks for jvm-alternate.lua. Run it from the repo root with
--   nvim --headless -l modules/home/nvim/languages/java/jvm-alternate-test.lua
-- or via `nix flake check`, which passes the module path as the first argument.
local M = dofile(arg[1] or "modules/home/nvim/languages/java/jvm-alternate.lua")

-- Path logic, with a stubbed `exists` so no files are needed.
local R = "/p"

local function check(desc, from, present, want)
    local set = {}
    for _, p in ipairs(present) do
        set[p] = true
    end
    local got, err = M.target(from, function(p)
        return set[p]
    end)
    assert(got == want, ("%s\n  got:  %s\n  want: %s\n  err:  %s"):format(desc, got, want, err))
end

-- main -> test: an existing file wins, whatever its suffix
for _, s in ipairs({ "Test", "Tests", "Spec", "Specification" }) do
    check(
        "java main -> " .. s,
        R .. "/src/main/java/com/foo/Bar.java",
        { R .. "/src/test/java/com/foo/Bar" .. s .. ".java" },
        R .. "/src/test/java/com/foo/Bar" .. s .. ".java"
    )
end

check(
    "kotlin main -> test",
    R .. "/src/main/kotlin/com/foo/Bar.kt",
    { R .. "/src/test/kotlin/com/foo/BarTest.kt" },
    R .. "/src/test/kotlin/com/foo/BarTest.kt"
)

check(
    "groovy main -> spec",
    R .. "/src/main/groovy/com/foo/Bar.groovy",
    { R .. "/src/test/groovy/com/foo/BarSpec.groovy" },
    R .. "/src/test/groovy/com/foo/BarSpec.groovy"
)

check(
    "java main -> groovy spock spec",
    R .. "/src/main/java/com/foo/Bar.java",
    { R .. "/src/test/groovy/com/foo/BarSpecification.groovy" },
    R .. "/src/test/groovy/com/foo/BarSpecification.groovy"
)

check(
    "java main -> nothing exists, defaults to Test.java",
    R .. "/src/main/java/com/foo/Bar.java",
    {},
    R .. "/src/test/java/com/foo/BarTest.java"
)

check(
    "kotlin main -> nothing exists, defaults to Test.kt",
    R .. "/src/main/kotlin/com/foo/Bar.kt",
    {},
    R .. "/src/test/kotlin/com/foo/BarTest.kt"
)

check("default package", R .. "/src/main/java/Bar.java", {}, R .. "/src/test/java/BarTest.java")

-- test -> main: every suffix stripped
for _, s in ipairs({ "Test", "Tests", "Spec", "Specification" }) do
    check(
        "java " .. s .. " -> main",
        R .. "/src/test/java/com/foo/Bar" .. s .. ".java",
        { R .. "/src/main/java/com/foo/Bar.java" },
        R .. "/src/main/java/com/foo/Bar.java"
    )
end

check(
    "groovy spec -> java main",
    R .. "/src/test/groovy/com/foo/BarSpec.groovy",
    { R .. "/src/main/java/com/foo/Bar.java" },
    R .. "/src/main/java/com/foo/Bar.java"
)

check(
    "test with no suffix -> same name in main",
    R .. "/src/test/java/com/foo/TestUtils.java",
    { R .. "/src/main/java/com/foo/TestUtils.java" },
    R .. "/src/main/java/com/foo/TestUtils.java"
)

check(
    "test -> main, nothing exists",
    R .. "/src/test/java/com/foo/BarTest.java",
    {},
    R .. "/src/main/java/com/foo/Bar.java"
)

check(
    "other source set treated as test side",
    R .. "/src/integrationTest/java/com/foo/BarTest.java",
    { R .. "/src/main/java/com/foo/Bar.java" },
    R .. "/src/main/java/com/foo/Bar.java"
)

local got, err = M.target("/tmp/scratch.txt", function()
    return false
end)
assert(got == nil and err:match("Maven/Gradle"), "expected a warning for a non-JVM path")

-- Skeleton for a file that does not exist yet
local function check_skeleton(desc, path, want)
    local got = table.concat(M.skeleton(path), "\n")
    assert(got == want, ("%s\n  got:\n%s\n  want:\n%s"):format(desc, got, want))
end

check_skeleton("java skeleton", R .. "/src/test/java/com/foo/BarTest.java", "package com.foo;\n\nclass BarTest {\n\n}")
check_skeleton(
    "kotlin skeleton has no semicolon",
    R .. "/src/test/kotlin/com/foo/BarTest.kt",
    "package com.foo\n\nclass BarTest {\n\n}"
)
check_skeleton(
    "groovy skeleton has no semicolon",
    R .. "/src/test/groovy/com/foo/BarTest.groovy",
    "package com.foo\n\nclass BarTest {\n\n}"
)
check_skeleton("default package has no package declaration", R .. "/src/test/java/BarTest.java", "class BarTest {\n\n}")
assert(M.skeleton("/tmp/scratch.txt") == nil, "expected no skeleton for a non-JVM path")

-- Round trip on real files: the buffer-local keymap, the jump, and creating a
-- test whose package directory does not exist yet.
vim.g.mapleader = " "
vim.cmd("filetype on")

local root = vim.fn.tempname()
for _, f in ipairs({
    "/src/main/java/com/foo/Bar.java",
    "/src/main/java/com/foo/Baz.java",
    "/src/test/groovy/com/foo/BarSpec.groovy",
}) do
    vim.fn.mkdir(vim.fs.dirname(root .. f), "p")
    vim.fn.writefile({}, root .. f)
end

local function jump_from(f)
    vim.cmd.edit(f)
    local map = vim.fn.maparg("<leader>t", "n", false, true)
    assert(map.buffer == 1, "no buffer-local <leader>t in a " .. vim.bo.filetype .. " buffer")
    map.callback()
    return vim.api.nvim_buf_get_name(0)
end

local to_spec = jump_from(root .. "/src/main/java/com/foo/Bar.java")
assert(to_spec == root .. "/src/test/groovy/com/foo/BarSpec.groovy", "java -> groovy spec: " .. to_spec)

local back = jump_from(to_spec)
assert(back == root .. "/src/main/java/com/foo/Bar.java", "groovy spec -> java: " .. back)

local new = jump_from(root .. "/src/main/java/com/foo/Baz.java")
assert(new == root .. "/src/test/java/com/foo/BazTest.java", "missing test not created at: " .. new)
local body = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert(body == "package com.foo;\n\nclass BazTest {\n\n}", "new buffer was not seeded:\n" .. body)
assert(vim.api.nvim_win_get_cursor(0)[1] == 4, "cursor is not inside the class body")
vim.cmd("silent write")
assert(vim.fn.filereadable(new) == 1, "new test file did not save")

-- Jumping to a file that exists must not seed anything.
local existing = jump_from(root .. "/src/main/java/com/foo/Bar.java")
assert(existing == root .. "/src/test/groovy/com/foo/BarSpec.groovy", "unexpected target: " .. existing)
assert(vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == "", "existing file was overwritten")

vim.fn.delete(root, "rf")
print("all ok")
