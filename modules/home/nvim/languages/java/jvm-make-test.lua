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
assert(vim.bo.errorformat:match("^%%f:%%l: error:"), "gradle errorformat: " .. vim.bo.errorformat)
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

print("all ok")
