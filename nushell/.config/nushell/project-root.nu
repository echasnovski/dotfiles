# Finding root ================================================================
# Root markers are file/directory relative paths (i.e. just name or path in
# subdirectory) or glob patterns to be checked for each ancestor.
#
# Each marker marks a root for a project of particular set of languages.
# Each marker can be one of:
# - "name": just check file existence; fast but rigid.
# - "glob": try to match with `glob`; flexible but slow.
# Each marker's languages has a score showing how confident this marker is
# for a particular language (bigger value -> bigger confidence).
#
# Special language `*` is present to mark generic project root.
# Its score will be added to path's real language scores to make the path
# more confident that it is actually a project root.
#
# Example of root markers data structure:
#   [
#     { marker: '.git',         type: "name", langs: { '*': 5 } }
#     { marker: 'README',       type: "name", langs: { '*': 2 } }
#     { marker: 'Cargo.toml',   type: "name", langs: { 'rust': 2 } },
#     { marker: 'node_modules', type: "name", langs: { javascript: 1, typescript: 1 } },
#     { marker: "*.csproj",     type: "glob", langs: { "csharp": 1 } },
#   ]
#
# Finding project and its language for a `path` is done as follows:
# - Compute language scores for `path` and each its ancestor:
#     - Try each root marker's glob as if searched from the target path.
#       If it has matches, add all marker's language scores to tracking table.
#
#   Example output for 'home/user/repos/rust-project/subdir' is something like:
#   [
#     {}                    # for '/home/user/repos/rust-project/subdir'
#     { '*': 7, 'rust': 2 } # for '/home/user/repos/rust-project'
#     {}                    # for '/home/user/repos'
#     { '*': 2}             # for '/home/user'
#     {}                    # for '/home'
#     {}                    # for '/'
#   ]
#
#   NOTE: language scores for each path is cached in the in-memory database
#   to speed up the process.
#
# - The output path is the one with the highest total language score:
#   `score of "*"` + `maximum of other scores`. The output language is the
#   language (not `*`) with maximum score. If only '*' is present, return
#   language 'none'. NOTE: to reduce possibility of ties, use slightly
#   different languages scores (can be floats instead of integers).
#   Based on example output, project root is '/home/user/repos/rust-project'
#   with language 'rust'.

# Built-in root markers. Not very common glob root markers are commented out
# for performance. Uncomment to respect them also at the cost of the more delay
# after the first (and at most the first) computation for a particular path.
const root_markers = [
  # Generally adopted files in project root
  { marker: ".editorconfig", type: "name", langs: { "*": 2 } },
  { marker: ".git",          type: "name", langs: { "*": 5 } },
  { marker: ".root",         type: "name", langs: { "*": 2 } },
  { marker: "CHANGELOG*",    type: "glob", langs: { "*": 2 } },
  { marker: "CONTRIBUTING*", type: "glob", langs: { "*": 2 } },
  { marker: "LICENSE*",      type: "glob", langs: { "*": 2 } },
  { marker: "COPYING",       type: "glob", langs: { "*": 2 } },
  { marker: "COPYRIGHT",     type: "glob", langs: { "*": 2 } },
  { marker: "NEWS*",         type: "glob", langs: { "*": 2 } },
  { marker: "README*",       type: "glob", langs: { "*": 2 } },

  # Build files, usually located in project root
  # { marker: "*.mk",              type: "glob", langs: { "*": 2 } },
  { marker: ".buckconfig",       type: "name", langs: { "*": 2 } },
  { marker: ".gn",               type: "name", langs: { "*": 2 } },
  { marker: ".plzconfig",        type: "name", langs: { "*": 2 } },
  # { marker: ".plzconfig.*",      type: "glob", langs: { "*": 2 } },
  { marker: "BUILD",             type: "name", langs: { "*": 2 } },
  { marker: "BUILD.bazel",       type: "name", langs: { "*": 2 } },
  { marker: "CMakePresets.json", type: "name", langs: { "*": 2 } },
  { marker: "Dockerfile",        type: "name", langs: { "*": 2 } },
  { marker: "MODULE.bazel",      type: "name", langs: { "*": 2 } },
  { marker: "Makefile",          type: "name", langs: { "*": 2 } },
  { marker: "WORKSPACE.bazel",   type: "name", langs: { "*": 2 } },
  { marker: "build",             type: "name", langs: { "*": 2 } },
  { marker: "build.zig",         type: "name", langs: { "*": 2 } },
  { marker: "cmake",             type: "name", langs: { "*": 2 } },
  { marker: "meson.build",       type: "name", langs: { "*": 2 } },
  { marker: "meson.options",     type: "name", langs: { "*": 2 } },
  { marker: "meson_options.txt", type: "name", langs: { "*": 2 } },

  # More or less single-language globs
  # { marker: "*.adc",      type: "glob", langs: { "ada": 1 } },
  # { marker: "*.gpr",      type: "glob", langs: { "ada": 1 } },
  { marker: "alire.toml", type: "name", langs: { "ada": 1 } },

  # { marker: "*.ino", type: "glob", langs: { "arduino": 1 } },

  { marker: ".asm-lsp.toml", type: "name", langs: { "asm": 1 } },
  { marker: ".hlasmplugin",  type: "name", langs: { "asm": 1 } },

  { marker: ".ccls",             type: "name", langs: { "c": 1, "cpp": 1 } },
  { marker: ".clang-format",     type: "name", langs: { "c": 1, "cpp": 1 } },
  { marker: ".clang-tidy",       type: "name", langs: { "c": 1, "cpp": 1 } },
  { marker: ".clangd",           type: "name", langs: { "c": 1, "cpp": 1 } },
  { marker: "compile_flags.txt", type: "name", langs: { "c": 1, "cpp": 1 } },
  { marker: "configure.ac",      type: "name", langs: { "c": 1, "cpp": 1 } },

  { marker: "Scarb.toml",         type: "name", langs: { "cairo": 1 } },
  { marker: "cairo_project.toml", type: "name", langs: { "cairo": 1 } },

  { marker: "bb.edn",          type: "name", langs: { "clojure": 1 } },
  { marker: "build.boot",      type: "name", langs: { "clojure": 1 } },
  { marker: "deps.edn",        type: "name", langs: { "clojure": 1 } },
  { marker: "project.clj",     type: "name", langs: { "clojure": 1 } },
  { marker: "shadow-cljs.edn", type: "name", langs: { "clojure": 1 } },

  { marker: "shard.yml", type: "name", langs: { "crystal": 1 } },

  # { marker: "*.csproj",       type: "glob", langs: { "csharp": 1 } },
  # { marker: "*.fsproj",       type: "glob", langs: { "fsharp": 1 } },
  # { marker: "*.sln",          type: "glob", langs: { "csharp": 1, "fsharp": 1 } },
  # { marker: "*.slnx",         type: "glob", langs: { "csharp": 1 } },
  { marker: "function.json",  type: "name", langs: { "csharp": 1, "visualbasic": 1 } },
  { marker: "omnisharp.json", type: "name", langs: { "csharp": 1, "visualbasic": 1 } },

  { marker: "Camera.src",     type: "name", langs: { "d": 1 } },
  { marker: "Gothic.src",     type: "name", langs: { "d": 1 } },
  { marker: "Menu.src",       type: "name", langs: { "d": 1 } },
  { marker: "Music.src",      type: "name", langs: { "d": 1 } },
  { marker: "ParticleFX.src", type: "name", langs: { "d": 1 } },
  { marker: "SFX.src",        type: "name", langs: { "d": 1 } },
  { marker: "VisualFX.src",   type: "name", langs: { "d": 1 } },
  { marker: "dub.json",       type: "name", langs: { "d": 1 } },
  { marker: "dub.sdl",        type: "name", langs: { "d": 1 } },

  { marker: "pubspec.yaml", type: "name", langs: { "dart": 1 } },

  { marker: "mix.exs", type: "name", langs: { "elixir": 1 } },

  { marker: "elm.json", type: "name", langs: { "elm": 1 } },

  { marker: "package.er", type: "name", langs: { "erg": 1 } },

  { marker: "erlang.mk",    type: "name", langs: { "erlang": 1 } },
  { marker: "rebar.config", type: "name", langs: { "erlang": 1 } },

  { marker: "flsproject.fnl", type: "name", langs: { "fennel": 1 } },

  { marker: "config.fish", type: "name", langs: { "fish": 1 } },

  { marker: ".fortls", type: "name", langs: { "fortran": 1 } },

  { marker: "gleam.toml", type: "name", langs: { "gleam": 1 } },

  { marker: ".golangci.json", type: "name", langs: { "go": 1 } },
  { marker: ".golangci.toml", type: "name", langs: { "go": 1 } },
  { marker: ".golangci.yaml", type: "name", langs: { "go": 1 } },
  { marker: ".golangci.yml",  type: "name", langs: { "go": 1 } },
  { marker: "go.mod",         type: "name", langs: { "go": 2 } },
  { marker: "go.work",        type: "name", langs: { "go": 2 } },

  { marker: "project.godot", type: "name", langs: { "godot": 2 } },

  # { marker: ".graphql.config.*", type: "glob", langs: { "graphql": 1 } },
  # { marker: ".graphqlrc*",       type: "glob", langs: { "graphql": 1 } },
  # { marker: "graphql.config.*",  type: "glob", langs: { "graphql": 1 } },

  # { marker: "*.cabal",       type: "glob", langs: { "haskell": 1 } },
  { marker: "cabal.config",  type: "name", langs: { "haskell": 1 } },
  { marker: "cabal.project", type: "name", langs: { "haskell": 1 } },
  { marker: "hie-bios",      type: "name", langs: { "haskell": 1 } },
  { marker: "hie.yaml",      type: "name", langs: { "haskell": 1 } },
  { marker: "package.yaml",  type: "name", langs: { "haskell": 1 } },
  { marker: "stack.yaml",    type: "name", langs: { "haskell": 1 } },

  { marker: "project.janet", type: "name", langs: { "janet": 1 } },

  { marker: "build.gradle",        type: "name", langs: { "java": 1, "kotlin": 1, "scala": 1 } },
  { marker: "build.gradle.kts",    type: "name", langs: { "java": 1, "kotlin": 1, "smithy": 1 } },
  { marker: "build.sbt",           type: "name", langs: { "scala": 1 } },
  { marker: "build.sc",            type: "name", langs: { "scala": 1 } },
  { marker: "build.xml",           type: "name", langs: { "java": 1, "kotlin": 1 } },
  { marker: "pom.xml",             type: "name", langs: { "java": 1, "kotlin": 1, "scala": 1 } },
  { marker: "settings.gradle",     type: "name", langs: { "java": 1, "kotlin": 1 } },
  { marker: "settings.gradle.kts", type: "name", langs: { "java": 1, "kotlin": 1 } },
  { marker: "smithy-build.json",   type: "name", langs: { "smithy": 1 } },
  { marker: "workspace.json",      type: "name", langs: { "kotlin": 1 } },

  { marker: ".flowconfig",        type: "name", langs: { "javascript": 1 } },
  { marker: ".oxlintrc.json",     type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "angular.json",       type: "name", langs: { "typescript": 1 } },
  { marker: "deno.json",          type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "deno.jsonc",         type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "ember-cli-build.js", type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "jsconfig.json",      type: "name", langs: { "javascript": 2, "typescript": 1 } },
  { marker: "node_modules",       type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "nx.json",            type: "name", langs: { "typescript": 1 } },
  { marker: "sfdx-project.json",  type: "name", langs: { "javascript": 1 } },
  { marker: "tsconfig.json",      type: "name", langs: { "typescript": 2 } },

  { marker: "Jenkinsfile", type: "name", langs: { "jenkins": 1 } },

  { marker: "JuliaProject.toml", type: "name", langs: { "julia": 1 } },
  { marker: "Project.toml",      type: "name", langs: { "julia": 1 } },

  { marker: "lean/library", type: "name", langs: { "lean": 1 } },
  { marker: "leanpkg.path", type: "name", langs: { "lean": 1 } },
  { marker: "leanpkg.toml", type: "name", langs: { "lean": 1 } },

  { marker: ".emmyrc.json", type: "name", langs: { "lua": 1 } },
  { marker: ".luacheckrc",  type: "name", langs: { "lua": 1 } },
  { marker: ".luarc.json",  type: "name", langs: { "lua": 1 } },
  { marker: ".luarc.jsonc", type: "name", langs: { "lua": 1 } },
  { marker: ".stylua.toml", type: "name", langs: { "lua": 1 } },
  { marker: "selene.toml",  type: "name", langs: { "lua": 1 } },
  { marker: "selene.yml",   type: "name", langs: { "lua": 1 } },
  { marker: "stylua.toml",  type: "name", langs: { "lua": 1 } },

  { marker: "nginx.conf", type: "name", langs: { "nginx": 1 } },

  # { marker: "*.nimble", type: "glob", langs: { "nim": 1 } },

  { marker: "flake.nix", type: "name", langs: { "nix": 1 } },
  { marker: "shell.nix", type: "name", langs: { "nix": 1 } },

  { marker: "config.nu", type: "name", langs: { "nu": 1 } },

  # { marker: "*.opam",         type: "glob", langs: { "ocaml": 1 } },
  { marker: "dune-project",   type: "name", langs: { "ocaml": 1 } },
  { marker: "dune-workspace", type: "name", langs: { "ocaml": 1 } },
  { marker: "esy.json",       type: "name", langs: { "ocaml": 1 } },

  # { marker: "*.odin",   type: "glob", langs: { "odin": 1 } },
  { marker: "ols.json", type: "name", langs: { "odin": 1 } },

  # { marker: "*.lpi", type: "glob", langs: { "pascal": 1 } },
  # { marker: "*.lpk", type: "glob", langs: { "pascal": 1 } },

  # { marker: "*.p8", type: "glob", langs: { "pico-8": 1 } },

  { marker: ".hhconfig",      type: "name", langs: { "php": 1 } },
  { marker: ".phpactor.json", type: "name", langs: { "php": 1 } },
  { marker: ".phpactor.yml",  type: "name", langs: { "php": 1 } },
  { marker: "Gemfile",        type: "name", langs: { "php": 1, "ruby": 1 } },
  { marker: "artisan",        type: "name", langs: { "php": 1 } },
  { marker: "composer.json",  type: "name", langs: { "php": 1 } },
  { marker: "composer.lock",  type: "name", langs: { "php": 1 } },
  { marker: "phpunit.xml",    type: "name", langs: { "php": 1 } },
  { marker: "psalm.xml",      type: "name", langs: { "php": 1 } },
  { marker: "psalm.xml.dist", type: "name", langs: { "php": 1 } },

  { marker: ".pliplugin", type: "name", langs: { "pli": 1 } },

  { marker: "pack.pl", type: "name", langs: { "prolog": 1 } },

  { marker: "bower.json",       type: "name", langs: { "purescript": 1 } },
  { marker: "psc-package.json", type: "name", langs: { "purescript": 1 } },
  { marker: "spago.dhall",      type: "name", langs: { "purescript": 1 } },
  { marker: "spago.yaml",       type: "name", langs: { "purescript": 1 } },

  { marker: ".pyre_configuration", type: "name", langs: { "python": 1 } },
  { marker: ".ruff.toml",          type: "name", langs: { "python": 1 } },
  { marker: "Pipfile",             type: "name", langs: { "python": 1 } },
  { marker: "conda.yaml",          type: "name", langs: { "python": 1 } },
  { marker: "pyproject.toml",      type: "name", langs: { "python": 1 } },
  { marker: "pyrefly.toml",        type: "name", langs: { "python": 1 } },
  { marker: "pyrightconfig.json",  type: "name", langs: { "python": 1 } },
  { marker: "requirements.txt",    type: "name", langs: { "python": 1 } },
  { marker: "ruff.toml",           type: "name", langs: { "python": 1 } },
  { marker: "setup.cfg",           type: "name", langs: { "python": 1 } },
  { marker: "setup.py",            type: "name", langs: { "python": 1 } },
  { marker: "tox.ini",             type: "name", langs: { "python": 1 } },
  { marker: "ty.toml",             type: "name", langs: { "python": 1 } },

  { marker: ".air.toml",   type: "name", langs: { "r": 1 } },
  { marker: "DESCRIPTION", type: "name", langs: { "r": 2 } },
  { marker: "NAMESPACE",   type: "name", langs: { "r": 2 } },
  { marker: "air.toml",    type: "name", langs: { "r": 1 } },

  { marker: "bsconfig.json", type: "name", langs: { "rescript": 1 } },
  { marker: "rescript.json", type: "name", langs: { "rescript": 1 } },

  { marker: "robot.toml",    type: "name", langs: { "robot": 1 } },
  { marker: "robot.yaml",    type: "name", langs: { "robot": 1 } },
  { marker: "robotidy.toml", type: "name", langs: { "robot": 1 } },

  { marker: ".streerc",  type: "name", langs: { "ruby": 1 } },
  { marker: "Steepfile", type: "name", langs: { "ruby": 1 } },

  { marker: ".bacon-locations",  type: "name", langs: { "rust": 1 } },
  { marker: ".rustfmt.toml",     type: "name", langs: { "rust": 1 } },
  { marker: "Cargo.toml",        type: "name", langs: { "rust": 2 } },
  { marker: "build.rs",          type: "name", langs: { "rust": 2 } },
  { marker: "rust-project.json", type: "name", langs: { "rust": 2 } },
  { marker: "rustfmt.toml",      type: "name", langs: { "rust": 1 } },

  { marker: "Akku.manifest", type: "name", langs: { "scheme": 1 } },
  { marker: "guix.scm",      type: "name", langs: { "scheme": 1 } },

  { marker: "millet.toml", type: "name", langs: { "sml": 1 } },

  { marker: "ape-config.yaml",   type: "name", langs: { "solidity": 1 } },
  { marker: "foundry.toml",      type: "name", langs: { "solidity": 1 } },
  # { marker: "hardhat.config.*",  type: "glob", langs: { "solidity": 1 } },
  { marker: "remappings.txt",    type: "name", langs: { "solidity": 1 } },
  { marker: "truffle-config.js", type: "name", langs: { "solidity": 1 } },
  { marker: "truffle.js",        type: "name", langs: { "solidity": 1 } },

  { marker: ".sqllsrc.json",       type: "name", langs: { "sql": 1 } },
  { marker: ".sqruff",             type: "name", langs: { "sql": 1 } },
  { marker: "config.yml",          type: "name", langs: { "sql": 1 } },
  { marker: "postgrestools.jsonc", type: "name", langs: { "sql": 1 } },

  # { marker: "*.xcodeproj",           type: "glob", langs: { "swift": 1 } },
  # { marker: "*.xcworkspace",         type: "glob", langs: { "swift": 1 } },
  { marker: "Package.swift",         type: "name", langs: { "swift": 1 } },
  { marker: "buildServer.json",      type: "name", langs: { "swift": 1 } },
  { marker: "compile_commands.json", type: "name", langs: { "swift": 1, "c": 1, "cpp": 1 } },

  { marker: "tlconfig.lua", type: "name", langs: { "teal": 1 } },

  { marker: ".terraform",  type: "name", langs: { "terraform": 1 } },
  { marker: ".tflint.hcl", type: "name", langs: { "terraform": 1 } },

  { marker: ".latexmkrc",    type: "name", langs: { "tex": 1 } },
  { marker: ".texlabroot",   type: "name", langs: { "tex": 1 } },
  { marker: ".vale.ini",     type: "name", langs: { "tex": 1 } },
  { marker: "Tectonic.toml", type: "name", langs: { "tex": 1 } },
  { marker: "latexmkrc",     type: "name", langs: { "tex": 1 } },
  { marker: "texlabroot",    type: "name", langs: { "tex": 1 } },

  { marker: ".fmt.ua", type: "name", langs: { "uiua": 1 } },
  { marker: "main.ua", type: "name", langs: { "uiua": 1 } },

  { marker: "v.mod", type: "name", langs: { "v": 1 } },

  { marker: ".svlangserver", type: "name", langs: { "verilog": 1 } },

  { marker: ".vhdl_ls.toml", type: "name", langs: { "vhdl": 1 } },
  { marker: "hdl-prj.json",  type: "name", langs: { "vhdl": 1 } },
  { marker: "vhdl_ls.toml",  type: "name", langs: { "vhdl": 1 } },

  { marker: "css",              type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: "uno.config.js",    type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: "uno.config.ts",    type: "name", langs: { "web": 1, "typescript": 1 } },
  { marker: "unocss.config.js", type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: "unocss.config.ts", type: "name", langs: { "web": 1, "typescript": 1 } },

  { marker: "zls.json", type: "name", langs: { "zig": 1 } },

  # Multi-language globs
  { marker: "package.json", type: "name", langs: { "javascript": 2, "typescript": 2 } },

  { marker: ".dprint.json",  type: "name", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },
  { marker: ".dprint.jsonc", type: "name", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },

  { marker: ".eslintrc",      type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.cjs",  type: "name", langs: { "javascript": 1 } },
  { marker: ".eslintrc.js",   type: "name", langs: { "javascript": 1 } },
  { marker: ".eslintrc.json", type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.yaml", type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.yml",  type: "name", langs: { "javascript": 1, "typescript": 1 } },

  { marker: ".snyk", type: "name", langs: { "go": 1, "javascript": 1, "python": 1, "terraform": 1, "typescript": 1 } },

  { marker: ".stylelintrc",         type: "name", langs: { "web": 1 } },
  { marker: ".stylelintrc.cjs",     type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: ".stylelintrc.js",      type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: ".stylelintrc.json",    type: "name", langs: { "web": 1 } },
  { marker: ".stylelintrc.mjs",     type: "name", langs: { "web": 1, "javascript": 1 } },
  { marker: ".stylelintrc.yaml",    type: "name", langs: { "web": 1 } },
  { marker: ".stylelintrc.yml",     type: "name", langs: { "web": 1 } },
  { marker: "stylelint.config.cjs", type: "name", langs: { "web": 1 } },
  { marker: "stylelint.config.js",  type: "name", langs: { "web": 1 } },
  { marker: "stylelint.config.mjs", type: "name", langs: { "web": 1 } },

  { marker: "app/assets/stylesheets/application.tailwind.css", type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "app/assets/tailwind/application.css",             type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.cjs",                      type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.js",                       type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.mjs",                      type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.ts",                       type: "name", langs: { "web": 1, "typescript": 1, "php": 1 } },
  { marker: "tailwind.config.cjs",                             type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.js",                              type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.mjs",                             type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.ts",                              type: "name", langs: { "web": 1, "typescript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.cjs",            type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.js",             type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.mjs",            type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.ts",             type: "name", langs: { "web": 1, "typescript": 1, "php": 1 } },

  { marker: "biome.json",  type: "name", langs: { "web": 1, "graphql": 1, "javascript": 1, "typescript": 1 } },
  { marker: "biome.jsonc", type: "name", langs: { "web": 1, "graphql": 1, "javascript": 1, "typescript": 1 } },

  { marker: "dprint.json",  type: "name", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },
  { marker: "dprint.jsonc", type: "name", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },

  { marker: "eslint.config.cjs", type: "name", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "eslint.config.cts", type: "name", langs: { "typescript": 1 } },
  { marker: "eslint.config.js",  type: "name", langs: { "javascript": 1 } },
  { marker: "eslint.config.mjs", type: "name", langs: { "javascript": 1 } },
  { marker: "eslint.config.mts", type: "name", langs: { "typescript": 1 } },
  { marker: "eslint.config.ts",  type: "name", langs: { "typescript": 1 } },

  { marker: "postcss.config.cjs",                 type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.js",                  type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.mjs",                 type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.ts",                  type: "name", langs: { "web": 1, "typescript": 1, "php": 1 } },
  { marker: "theme/static_src/postcss.config.js", type: "name", langs: { "web": 1, "javascript": 1, "php": 1 } },

  {
    marker: "sgconfig.yaml",
    type: "name",
    langs: { "c": 1, "cpp": 1, "web": 1, "dart": 1, "go": 1, "java": 1, "javascript": 1, "kotlin": 1, "lua": 1, "python": 1, "rust": 1, "typescript": 1 }
  },
  {
    marker: "sgconfig.yml",
    type: "name",
    langs: { "c": 1, "cpp": 1, "web": 1, "dart": 1, "go": 1, "java": 1, "javascript": 1, "kotlin": 1, "lua": 1, "python": 1, "rust": 1, "typescript": 1 }
  },
]

export def get_project_root [path: path]: nothing -> record {
  let init = { cur_root: { path: $path, langs: [], score: 0 }, cur_path: '' }
  let data = $path | path split | reduce --fold $init {
    |dir, state|
    let cur_path = $state.cur_path | path join $dir
    let cur_path_langs = get_path_langs $cur_path
    # NOTE: Compare with `<=` to prefer deeper directory if scores are the same.
    # For example, matters if `root_markers` contains only '.git' glob.
    let new_root = if ($state.cur_root.score <= $cur_path_langs.score) {$cur_path_langs} else {$state.cur_root}
    { cur_root: $new_root, cur_path: $cur_path }
  }

  $data | get cur_root
}

export def get_path_langs [path: path]: nothing -> record {
  # Try to first get from database (to avoid file system checks for performance)
  let cached = path_langs_cache_get $path
  if ($cached | is-not-empty) { return $cached }

  # Get only matching markers
  let matching_markers = $root_markers | where { |row| $path | has_root_marker $row }
  if ($matching_markers | is-empty) {
    return ({ path: $path, langs: [], score: 0 } | path_langs_cache_set)
  }

  # Get lang-score table
  let scores = $matching_markers |
    update langs { |row| $row.langs | transpose lang score } |
    get langs |
    flatten |
    # Summarize score for each lang
    group-by lang --to-table |
    insert score { |row| $row.items | get score | math sum }

  let generic_data = $scores | where { |row| $row.lang == '*' }
  let lang_data = $scores | where { |row| $row.lang != '*' }
  let generic_score = if ($generic_data | is-empty) { 0 } else { $generic_data | get score.0 }

  if ($lang_data | is-empty) {
    let res = if ($generic_data | is-empty) {
      { path: $path, langs: [], score: 0 }
    } else {
      { path: $path, langs: ['none'], score: $generic_score }
    }
    return ($res | path_langs_cache_set)
  }

  let max_lang_score = $lang_data | get score | math max
  let langs = $lang_data | where { |row| $row.score == $max_lang_score } | get lang

  # Cache for future performance gains and return
  { path: $path, langs: $langs, score: ($max_lang_score + $generic_score) } | path_langs_cache_set
}

def has_root_marker [root_marker: record]: path -> bool {
  let full = $in | path join $root_marker.marker
  if ($root_marker.type == "name") { $full | path exists } else { glob $full }
}

def path_langs_cache_get [path]: nothing -> record {
  let data = try {
    stor open | query db "select * from __path_langs WHERE path == :path" --params { path: $path }
  } catch {
    stor create --table-name __path_langs --columns { path: str, langs: str, score: int }
    null
  }
  if ($data == null) { return null }
  $data | update langs { |d| $d.langs | split row ',' } | into record
}

def path_langs_cache_set []: record -> record {
  let $res = $in
  $res |
    update langs { |d| $d.langs | str join ',' } |
    stor insert --table-name __path_langs
  $res
}

# Language icons ==============================================================
const lang_icons = {
  'ada': '󱁷 ',
  'arduino': ' ',
  'asm': ' ',
  'c': '󰙱 ',
  'cairo': '󰫰 ',
  'clojure': ' ',
  'cpp': '󰙲 ',
  'crystal': ' ',
  'csharp': '󰌛 ',
  'css': '󰌜 ',
  'd': ' ',
  'dart': ' ',
  'elixir': ' ',
  'elm': ' ',
  'erg': '󰫲 ',
  'erlang': ' ',
  'fennel': ' ',
  'fish': '󰈺 ',
  'fortran': '󱈚 ',
  'fsharp': ' ',
  'gleam': '󰦥 ',
  'go': '󰟓 ',
  'godot': ' ',
  'graphql': '󰡷 ',
  'haskell': '󰲒 ',
  'janet': '󰫷 ',
  'java': '󰬷 ',
  'javascript': '󰌞 ',
  'jenkins': ' ',
  'julia': ' ',
  'kotlin': '󱈙 ',
  'lean': '󱎦 ',
  'lua': '󰢱 ',
  'nginx': '󰰓 ',
  'nim': ' ',
  'nix': '󱄅 ',
  'nu': ' ',
  'ocaml': ' ',
  'odin': '󰮔 ',
  'pascal': '󱤊 ',
  'php': '󰌟 ',
  'pico-8': '󰢱 ',
  'pli': '󰫽 ',
  'prolog': ' ',
  'purescript': ' ',
  'python': '󰌠 ',
  'r': '󰟔 ',
  'rescript': '󰫿 ',
  'robot': '󰚩 ',
  'ruby': '󰴭 ',
  'rust': '󱘗 ',
  'scala': ' ',
  'scheme': '󰘧 ',
  'smithy': '󰬀 ',
  'sml': '󰘧 ',
  'solidity': ' ',
  'sql': '󰆼 ',
  'swift': '󰛥 ',
  'teal': '󰢱 ',
  'terraform': '󱁢 ',
  'tex': ' ',
  'typescript': '󰛦 ',
  'uiua': '󰬂 ',
  'v': ' ',
  'verilog': '󰍛 ',
  'vhdl': '󰍛 ',
  'visualbasic': '󰛤 ',
  'web': '󰖟 ',
  'zig': ' ',
}

export def get_lang_icon []: string -> string {
  let l = $in
  $lang_icons | default null $l | get $l
}
