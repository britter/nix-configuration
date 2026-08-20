-- Jump between a JVM source file and its test with <leader>t.
-- Assumes the Maven/Gradle layout <root>/src/<sourceSet>/<lang>/<package>/<Name>.<ext>.

local M = {}

local exts = { java = "java", kotlin = "kt", groovy = "groovy" }
local langs = { "java", "kotlin", "groovy" }
-- Longest first so Specification isn't stripped down to "Specifi" by Spec, and
-- Tests not to "Test" + leftover "s".
local suffixes = { "Specification", "Tests", "Test", "Spec" }

local function parse(path)
    -- pkg keeps its trailing slash and is empty for the default package. Lua
    -- patterns have no alternation, so the language dir is matched loosely and
    -- checked against exts afterwards.
    local root, set, lang, pkg, name = path:match("^(.*)/src/([^/]+)/([^/]+)/(.-)([^/]+)%.%a+$")
    if not root or not exts[lang] then
        return nil
    end
    return root, set, lang, pkg, name
end

-- Current language first: a Java class is far more likely to have a Java test
-- than a Kotlin one, but Spock specs for Java code are common enough to look for.
local function lang_order(lang)
    local order = { lang }
    for _, l in ipairs(langs) do
        if l ~= lang then
            order[#order + 1] = l
        end
    end
    return order
end

-- Returns the path to edit, or nil plus a message. `exists` is injectable for tests.
function M.target(path, exists)
    exists = exists or function(p)
        return vim.fn.filereadable(p) == 1
    end
    local root, set, lang, pkg, name = parse(path)
    if not root then
        return nil, "not a Maven/Gradle source layout: " .. path
    end

    if set == "main" then
        for _, l in ipairs(lang_order(lang)) do
            for _, s in ipairs(suffixes) do
                local cand = ("%s/src/test/%s/%s%s%s.%s"):format(root, l, pkg, name, s, exts[l])
                if exists(cand) then
                    return cand
                end
            end
        end
        -- Nothing there yet: default to creating a same-language ...Test file.
        return ("%s/src/test/%s/%s%sTest.%s"):format(root, lang, pkg, name, exts[lang])
    end

    local base = name
    for _, s in ipairs(suffixes) do
        local stripped = name:match("^(.+)" .. s .. "$")
        if stripped then
            base = stripped
            break
        end
    end
    for _, l in ipairs(lang_order(lang)) do
        local cand = ("%s/src/main/%s/%s%s.%s"):format(root, l, pkg, base, exts[l])
        if exists(cand) then
            return cand
        end
    end
    return ("%s/src/main/%s/%s%s.%s"):format(root, lang, pkg, base, exts[lang])
end

-- The package and class declaration a new file would otherwise start with.
-- Returns nil for a path outside the layout.
function M.skeleton(path)
    local _, _, lang, pkg, name = parse(path)
    if not lang then
        return nil
    end
    local lines = {}
    if pkg ~= "" then
        local decl = "package " .. (pkg:gsub("/$", ""):gsub("/", "."))
        table.insert(lines, lang == "java" and decl .. ";" or decl)
        table.insert(lines, "")
    end
    return vim.list_extend(lines, { "class " .. name .. " {", "", "}" })
end

function M.jump()
    local target, err = M.target(vim.fn.expand("%:p"))
    if not target then
        vim.notify(err, vim.log.levels.WARN)
        return
    end
    local is_new = vim.fn.filereadable(target) == 0
    -- The package directory may not exist yet when creating a test.
    vim.fn.mkdir(vim.fs.dirname(target), "p")
    vim.cmd.edit(vim.fn.fnameescape(target))

    -- Seed a new file, but never touch one that already has content: an
    -- unsaved buffer from an earlier jump is still empty on disk.
    local empty = vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == ""
    if is_new and empty then
        local lines = M.skeleton(target)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        -- Land inside the class body.
        vim.api.nvim_win_set_cursor(0, { #lines - 1, 0 })
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "java", "kotlin", "groovy" },
    callback = function(args)
        vim.keymap.set("n", "<leader>t", M.jump, {
            buffer = args.buf,
            desc = "Jump between source and test",
        })
    end,
})

return M
