# Root markers are glob patterns to be checked for each ancestor.
# Each marker marks a root for a project of particular set of languages.
# Each marker's languages has a score showing how confident this marker is
# for a particular language (bigger value -> bigger confidence).
#
# Special language `*` is present to mark generic project root.
# Its score will be added to path's real language scores to make the path
# more confident that it is actually a project root.
#
# Example of root markers data structure:
#   [
#     { marker: '.git',         langs: { '*': 5 } }
#     { marker: 'README',       langs: { '*': 2 } }
#     { marker: 'Cargo.toml',   langs: { 'rust': 2 } },
#     { marker: 'node_modules', langs: { javascript: 1, typescript: 1 } },
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
# - The output path is the one with the highest total language score:
#   `score of "*"` + `maximum of other scores`. The output language is the
#   language (not `*`) with maximum score. If only '*' is present, return
#   language 'none'.
#   Based on example output, project root is '/home/user/repos/rust-project'
#   with language 'rust'.
#   TODO: decide how to maybe better handle ties.

const root_markers = [
  # Generally adopted files in project root
  { marker: ".editorconfig", langs: { "*": 2 } },
  { marker: ".git",          langs: { "*": 5 } },
  { marker: ".root",         langs: { "*": 2 } },
  { marker: "CHANGELOG*",    langs: { "*": 2 } },
  { marker: "CONTRIBUTING*", langs: { "*": 2 } },
  { marker: "LICENSE*",      langs: { "*": 2 } },
  { marker: "NEWS*",         langs: { "*": 2 } },
  { marker: "README*",       langs: { "*": 2 } },

  # Build files, usually located in project root
  { marker: "*.mk",              langs: { "*": 2 } },
  { marker: ".buckconfig",       langs: { "*": 2 } },
  { marker: ".gn",               langs: { "*": 2 } },
  { marker: ".plzconfig",        langs: { "*": 2 } },
  { marker: ".plzconfig.*",      langs: { "*": 2 } },
  { marker: "BUILD",             langs: { "*": 2 } },
  { marker: "BUILD.bazel",       langs: { "*": 2 } },
  { marker: "CMakePresets.json", langs: { "*": 2 } },
  { marker: "Dockerfile",        langs: { "*": 2 } },
  { marker: "MODULE.bazel",      langs: { "*": 2 } },
  { marker: "Makefile",          langs: { "*": 2 } },
  { marker: "WORKSPACE.bazel",   langs: { "*": 2 } },
  { marker: "build",             langs: { "*": 2 } },
  { marker: "build.zig",         langs: { "*": 2 } },
  { marker: "cmake",             langs: { "*": 2 } },
  { marker: "meson.build",       langs: { "*": 2 } },
  { marker: "meson.options",     langs: { "*": 2 } },
  { marker: "meson_options.txt", langs: { "*": 2 } },

  # More or less single-language globs
  { marker: "*.adc",      langs: { "ada": 1 } },
  { marker: "*.gpr",      langs: { "ada": 1 } },
  { marker: "alire.toml", langs: { "ada": 1 } },

  { marker: "*.ino", langs: { "arduino": 1 } },

  { marker: ".asm-lsp.toml", langs: { "asm": 1 } },
  { marker: ".hlasmplugin",  langs: { "asm": 1 } },

  { marker: ".ccls",             langs: { "c": 1, "cpp": 1 } },
  { marker: ".clang-format",     langs: { "c": 1, "cpp": 1 } },
  { marker: ".clang-tidy",       langs: { "c": 1, "cpp": 1 } },
  { marker: ".clangd",           langs: { "c": 1, "cpp": 1 } },
  { marker: "compile_flags.txt", langs: { "c": 1, "cpp": 1 } },
  { marker: "configure.ac",      langs: { "c": 1, "cpp": 1 } },

  { marker: "Scarb.toml",         langs: { "cairo": 1 } },
  { marker: "cairo_project.toml", langs: { "cairo": 1 } },

  { marker: "bb.edn",          langs: { "clojure": 1 } },
  { marker: "build.boot",      langs: { "clojure": 1 } },
  { marker: "deps.edn",        langs: { "clojure": 1 } },
  { marker: "project.clj",     langs: { "clojure": 1 } },
  { marker: "shadow-cljs.edn", langs: { "clojure": 1 } },

  { marker: "shard.yml", langs: { "crystal": 1 } },

  { marker: "*.csproj",       langs: { "csharp": 1 } },
  { marker: "*.fsproj",       langs: { "fsharp": 1 } },
  { marker: "*.sln",          langs: { "csharp": 1, "fsharp": 1 } },
  { marker: "*.slnx",         langs: { "csharp": 1 } },
  { marker: "function.json",  langs: { "csharp": 1, "visualbasic": 1 } },
  { marker: "omnisharp.json", langs: { "csharp": 1, "visualbasic": 1 } },

  { marker: "uno.config.js",    langs: { "css": 1, "javascript": 1 } },
  { marker: "uno.config.ts",    langs: { "css": 1, "typescript": 1 } },
  { marker: "unocss.config.js", langs: { "css": 1, "javascript": 1 } },
  { marker: "unocss.config.ts", langs: { "css": 1, "typescript": 1 } },

  { marker: "Camera.src",     langs: { "d": 1 } },
  { marker: "Gothic.src",     langs: { "d": 1 } },
  { marker: "Menu.src",       langs: { "d": 1 } },
  { marker: "Music.src",      langs: { "d": 1 } },
  { marker: "ParticleFX.src", langs: { "d": 1 } },
  { marker: "SFX.src",        langs: { "d": 1 } },
  { marker: "VisualFX.src",   langs: { "d": 1 } },
  { marker: "dub.json",       langs: { "d": 1 } },
  { marker: "dub.sdl",        langs: { "d": 1 } },

  { marker: "pubspec.yaml", langs: { "dart": 1 } },

  { marker: "mix.exs", langs: { "elixir": 1 } },

  { marker: "elm.json", langs: { "elm": 1 } },

  { marker: "package.er", langs: { "erg": 1 } },

  { marker: "erlang.mk",    langs: { "erlang": 1 } },
  { marker: "rebar.config", langs: { "erlang": 1 } },

  { marker: "flsproject.fnl", langs: { "fennel": 1 } },

  { marker: "config.fish", langs: { "fish": 1 } },

  { marker: ".fortls", langs: { "fortran": 1 } },

  { marker: "gleam.toml", langs: { "gleam": 1 } },

  { marker: ".golangci.json", langs: { "go": 1 } },
  { marker: ".golangci.toml", langs: { "go": 1 } },
  { marker: ".golangci.yaml", langs: { "go": 1 } },
  { marker: ".golangci.yml",  langs: { "go": 1 } },
  { marker: "go.mod",         langs: { "go": 1 } },
  { marker: "go.work",        langs: { "go": 1 } },

  { marker: "project.godot", langs: { "godot": 1 } },

  { marker: ".graphql.config.*", langs: { "graphql": 1 } },
  { marker: ".graphqlrc*",       langs: { "graphql": 1 } },
  { marker: "graphql.config.*",  langs: { "graphql": 1 } },

  { marker: "*.cabal",       langs: { "haskell": 1 } },
  { marker: "cabal.config",  langs: { "haskell": 1 } },
  { marker: "cabal.project", langs: { "haskell": 1 } },
  { marker: "hie-bios",      langs: { "haskell": 1 } },
  { marker: "hie.yaml",      langs: { "haskell": 1 } },
  { marker: "package.yaml",  langs: { "haskell": 1 } },
  { marker: "stack.yaml",    langs: { "haskell": 1 } },

  { marker: "project.janet", langs: { "janet": 1 } },

  { marker: "build.gradle",        langs: { "java": 1, "kotlin": 1, "scala": 1 } },
  { marker: "build.gradle.kts",    langs: { "java": 1, "kotlin": 1, "smithy": 1 } },
  { marker: "build.sbt",           langs: { "scala": 1 } },
  { marker: "build.sc",            langs: { "scala": 1 } },
  { marker: "build.xml",           langs: { "java": 1, "kotlin": 1 } },
  { marker: "pom.xml",             langs: { "java": 1, "kotlin": 1, "scala": 1 } },
  { marker: "settings.gradle",     langs: { "java": 1, "kotlin": 1 } },
  { marker: "settings.gradle.kts", langs: { "java": 1, "kotlin": 1 } },
  { marker: "smithy-build.json",   langs: { "smithy": 1 } },
  { marker: "workspace.json",      langs: { "kotlin": 1 } },

  { marker: ".flowconfig",        langs: { "javascript": 1 } },
  { marker: ".oxlintrc.json",     langs: { "javascript": 1, "typescript": 1 } },
  { marker: "angular.json",       langs: { "typescript": 1 } },
  { marker: "deno.json",          langs: { "javascript": 1, "typescript": 1 } },
  { marker: "deno.jsonc",         langs: { "javascript": 1, "typescript": 1 } },
  { marker: "ember-cli-build.js", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "jsconfig.json",      langs: { "javascript": 2, "typescript": 1 } },
  { marker: "node_modules",       langs: { "javascript": 1, "typescript": 1 } },
  { marker: "nx.json",            langs: { "typescript": 1 } },
  { marker: "sfdx-project.json",  langs: { "javascript": 1 } },
  { marker: "tsconfig.json",      langs: { "typescript": 2 } },

  { marker: "Jenkinsfile", langs: { "jenkins": 1 } },

  { marker: "JuliaProject.toml", langs: { "julia": 1 } },
  { marker: "Project.toml",      langs: { "julia": 1 } },

  { marker: "lean/library", langs: { "lean": 1 } },
  { marker: "leanpkg.path", langs: { "lean": 1 } },
  { marker: "leanpkg.toml", langs: { "lean": 1 } },

  { marker: ".emmyrc.json", langs: { "lua": 1 } },
  { marker: ".luacheckrc",  langs: { "lua": 1 } },
  { marker: ".luarc.json",  langs: { "lua": 1 } },
  { marker: ".luarc.jsonc", langs: { "lua": 1 } },
  { marker: ".stylua.toml", langs: { "lua": 1 } },
  { marker: "selene.toml",  langs: { "lua": 1 } },
  { marker: "selene.yml",   langs: { "lua": 1 } },
  { marker: "stylua.toml",  langs: { "lua": 1 } },

  { marker: "nginx.conf", langs: { "nginx": 1 } },

  { marker: "*.nimble", langs: { "nim": 1 } },

  { marker: "flake.nix", langs: { "nix": 1 } },
  { marker: "shell.nix", langs: { "nix": 1 } },

  { marker: "config.nu", langs: { "nu": 1 } },

  { marker: "*.opam",         langs: { "ocaml": 1 } },
  { marker: "dune-project",   langs: { "ocaml": 1 } },
  { marker: "dune-workspace", langs: { "ocaml": 1 } },
  { marker: "esy.json",       langs: { "ocaml": 1 } },

  { marker: "*.odin",   langs: { "odin": 1 } },
  { marker: "ols.json", langs: { "odin": 1 } },

  { marker: "*.lpi", langs: { "pascal": 1 } },
  { marker: "*.lpk", langs: { "pascal": 1 } },

  { marker: "*.p8", langs: { "pico-8": 1 } },

  { marker: ".hhconfig",      langs: { "php": 1 } },
  { marker: ".phpactor.json", langs: { "php": 1 } },
  { marker: ".phpactor.yml",  langs: { "php": 1 } },
  { marker: "Gemfile",        langs: { "php": 1, "ruby": 1 } },
  { marker: "artisan",        langs: { "php": 1 } },
  { marker: "composer.json",  langs: { "php": 1 } },
  { marker: "composer.lock",  langs: { "php": 1 } },
  { marker: "phpunit.xml",    langs: { "php": 1 } },
  { marker: "psalm.xml",      langs: { "php": 1 } },
  { marker: "psalm.xml.dist", langs: { "php": 1 } },

  { marker: ".pliplugin", langs: { "pli": 1 } },

  { marker: "pack.pl", langs: { "prolog": 1 } },

  { marker: "bower.json",       langs: { "purescript": 1 } },
  { marker: "psc-package.json", langs: { "purescript": 1 } },
  { marker: "spago.dhall",      langs: { "purescript": 1 } },
  { marker: "spago.yaml",       langs: { "purescript": 1 } },

  { marker: ".pyre_configuration", langs: { "python": 1 } },
  { marker: ".ruff.toml",          langs: { "python": 1 } },
  { marker: "Pipfile",             langs: { "python": 1 } },
  { marker: "conda.yaml",          langs: { "python": 1 } },
  { marker: "pyproject.toml",      langs: { "python": 1 } },
  { marker: "pyrefly.toml",        langs: { "python": 1 } },
  { marker: "pyrightconfig.json",  langs: { "python": 1 } },
  { marker: "requirements.txt",    langs: { "python": 1 } },
  { marker: "ruff.toml",           langs: { "python": 1 } },
  { marker: "setup.cfg",           langs: { "python": 1 } },
  { marker: "setup.py",            langs: { "python": 1 } },
  { marker: "tox.ini",             langs: { "python": 1 } },
  { marker: "ty.toml",             langs: { "python": 1 } },

  { marker: ".air.toml",   langs: { "r": 1 } },
  { marker: "DESCRIPTION", langs: { "r": 1 } },
  { marker: "NAMESPACE",   langs: { "r": 1 } },
  { marker: "air.toml",    langs: { "r": 1 } },

  { marker: "bsconfig.json", langs: { "rescript": 1 } },
  { marker: "rescript.json", langs: { "rescript": 1 } },

  { marker: "robot.toml",    langs: { "robot": 1 } },
  { marker: "robot.yaml",    langs: { "robot": 1 } },
  { marker: "robotidy.toml", langs: { "robot": 1 } },

  { marker: ".streerc",  langs: { "ruby": 1 } },
  { marker: "Steepfile", langs: { "ruby": 1 } },

  { marker: ".bacon-locations",  langs: { "rust": 1 } },
  { marker: ".rustfmt.toml",     langs: { "rust": 1 } },
  { marker: "Cargo.toml",        langs: { "rust": 2 } },
  { marker: "rust-project.json", langs: { "rust": 2 } },
  { marker: "rustfmt.toml",      langs: { "rust": 1 } },

  { marker: "Akku.manifest", langs: { "scheme": 1 } },
  { marker: "guix.scm",      langs: { "scheme": 1 } },

  { marker: "millet.toml", langs: { "sml": 1 } },

  { marker: "ape-config.yaml",   langs: { "solidity": 1 } },
  { marker: "foundry.toml",      langs: { "solidity": 1 } },
  { marker: "hardhat.config.*",  langs: { "solidity": 1 } },
  { marker: "remappings.txt",    langs: { "solidity": 1 } },
  { marker: "truffle-config.js", langs: { "solidity": 1 } },
  { marker: "truffle.js",        langs: { "solidity": 1 } },

  { marker: ".sqllsrc.json",       langs: { "sql": 1 } },
  { marker: ".sqruff",             langs: { "sql": 1 } },
  { marker: "config.yml",          langs: { "sql": 1 } },
  { marker: "postgrestools.jsonc", langs: { "sql": 1 } },

  { marker: "*.xcodeproj",           langs: { "swift": 1 } },
  { marker: "*.xcworkspace",         langs: { "swift": 1 } },
  { marker: "Package.swift",         langs: { "swift": 1 } },
  { marker: "buildServer.json",      langs: { "swift": 1 } },
  { marker: "compile_commands.json", langs: { "swift": 1, "c": 1, "cpp": 1 } },

  { marker: "tlconfig.lua", langs: { "teal": 1 } },

  { marker: ".terraform",  langs: { "terraform": 1 } },
  { marker: ".tflint.hcl", langs: { "terraform": 1 } },

  { marker: ".latexmkrc",    langs: { "tex": 1 } },
  { marker: ".texlabroot",   langs: { "tex": 1 } },
  { marker: ".vale.ini",     langs: { "tex": 1 } },
  { marker: "Tectonic.toml", langs: { "tex": 1 } },
  { marker: "latexmkrc",     langs: { "tex": 1 } },
  { marker: "texlabroot",    langs: { "tex": 1 } },

  { marker: ".fmt.ua", langs: { "uiua": 1 } },
  { marker: "main.ua", langs: { "uiua": 1 } },

  { marker: "v.mod", langs: { "v": 1 } },

  { marker: ".svlangserver", langs: { "verilog": 1 } },

  { marker: ".vhdl_ls.toml", langs: { "vhdl": 1 } },
  { marker: "hdl-prj.json",  langs: { "vhdl": 1 } },
  { marker: "vhdl_ls.toml",  langs: { "vhdl": 1 } },

  { marker: "zls.json", langs: { "zig": 1 } },

  # Multi-language globs
  { marker: "package.json", langs: { "javascript": 2, "typescript": 2 } },

  { marker: ".dprint.json",  langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },
  { marker: ".dprint.jsonc", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },

  { marker: ".eslintrc",      langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.cjs",  langs: { "javascript": 1 } },
  { marker: ".eslintrc.js",   langs: { "javascript": 1 } },
  { marker: ".eslintrc.json", langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.yaml", langs: { "javascript": 1, "typescript": 1 } },
  { marker: ".eslintrc.yml",  langs: { "javascript": 1, "typescript": 1 } },

  { marker: ".snyk", langs: { "go": 1, "javascript": 1, "python": 1, "terraform": 1, "typescript": 1 } },

  { marker: ".stylelintrc",         langs: { "css": 1 } },
  { marker: ".stylelintrc.cjs",     langs: { "css": 1, "javascript": 1 } },
  { marker: ".stylelintrc.js",      langs: { "css": 1, "javascript": 1 } },
  { marker: ".stylelintrc.json",    langs: { "css": 1 } },
  { marker: ".stylelintrc.mjs",     langs: { "css": 1, "javascript": 1 } },
  { marker: ".stylelintrc.yaml",    langs: { "css": 1 } },
  { marker: ".stylelintrc.yml",     langs: { "css": 1 } },
  { marker: "stylelint.config.cjs", langs: { "css": 1 } },
  { marker: "stylelint.config.js",  langs: { "css": 1 } },
  { marker: "stylelint.config.mjs", langs: { "css": 1 } },

  { marker: "app/assets/stylesheets/application.tailwind.css", langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "app/assets/tailwind/application.css",             langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.cjs",                      langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.js",                       langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.mjs",                      langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "assets/tailwind.config.ts",                       langs: { "css": 1, "typescript": 1, "php": 1 } },
  { marker: "tailwind.config.cjs",                             langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.js",                              langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.mjs",                             langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "tailwind.config.ts",                              langs: { "css": 1, "typescript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.cjs",            langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.js",             langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.mjs",            langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "theme/static_src/tailwind.config.ts",             langs: { "css": 1, "typescript": 1, "php": 1 } },

  { marker: "biome.json",  langs: { "css": 1, "graphql": 1, "javascript": 1, "typescript": 1 } },
  { marker: "biome.jsonc", langs: { "css": 1, "graphql": 1, "javascript": 1, "typescript": 1 } },

  { marker: "dprint.json",  langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },
  { marker: "dprint.jsonc", langs: { "graphql": 1, "javascript": 1, "python": 1, "csharp": 1, "rust": 1, "typescript": 1 } },

  { marker: "eslint.config.cjs", langs: { "javascript": 1, "typescript": 1 } },
  { marker: "eslint.config.cts", langs: { "typescript": 1 } },
  { marker: "eslint.config.js",  langs: { "javascript": 1 } },
  { marker: "eslint.config.mjs", langs: { "javascript": 1 } },
  { marker: "eslint.config.mts", langs: { "typescript": 1 } },
  { marker: "eslint.config.ts",  langs: { "typescript": 1 } },

  { marker: "postcss.config.cjs",                 langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.js",                  langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.mjs",                 langs: { "css": 1, "javascript": 1, "php": 1 } },
  { marker: "postcss.config.ts",                  langs: { "css": 1, "typescript": 1, "php": 1 } },
  { marker: "theme/static_src/postcss.config.js", langs: { "css": 1, "javascript": 1, "php": 1 } },

  { marker: "sgconfig.yaml", langs: { "c": 1, "cpp": 1, "css": 1, "dart": 1, "go": 1, "java": 1, "javascript": 1, "kotlin": 1, "lua": 1, "python": 1, "rust": 1, "typescript": 1 } },
  { marker: "sgconfig.yml",  langs: { "c": 1, "cpp": 1, "css": 1, "dart": 1, "go": 1, "java": 1, "javascript": 1, "kotlin": 1, "lua": 1, "python": 1, "rust": 1, "typescript": 1 } },
]

export def get_root_markers [] {
  $root_markers
}

# TODO: Add in-memory caching (`stor query`) of `get_project_root` output

export def get_project_root [
  path: path
  --prefer-git, # Find first ancestor with '.git' file/directory and compute its language
]: nothing -> record {
  # TODO
  # let markers = if (--prefer-git) { git_markers } else { root_markers }
  #
  # mut cur_dir = $in
  # for i in 1..1000 {
  #   let parent_dir = $cur_dir | path dirname
  #   if ($parent_dir == $cur_dir) { break }
  #
  #   let cur_lang_scores = []
  #   for marker in $markers {
  #     let cur_glob: glob = $cur_dir | path join ($marker | get glob)
  #     let is_present = (glob $cur_glob | length) > 0
  #   }
  #
  #   mut cur_dir = $parent_dir
  # }
  #
  # { path: $in, lang: 'none' }

  # let path = try { git rev-parse --show-toplevel } catch { pwd }
  let path = (pwd)
  { path: $path, langs: [ 'none' ] }
}

# TODO: Add in-memory caching (`stor query`) for path's language scores

export def get_path_langs [path: path]: nothing -> record {
  # Get only matching markers
  let matching_markers = $root_markers |
    where { |row| (glob ($path | path join $row.marker) | length) > 0 }
  if ($matching_markers | is-empty) { return { langs: [], score: 0} }

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
    if ($generic_data | is-empty) { return { langs: [], score: 0 } }
    return { langs: ['none'], score: $generic_score }
  }

  let max_lang_score = $lang_data | get score | math max
  let langs = $lang_data | where { |row| $row.score == $max_lang_score } | get lang

  { langs: $langs, score: ($max_lang_score + $generic_score) }
}

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
  'zig': ' ',
}

export def get_lang_icon []: string -> string {
  let l = $in
  $lang_icons | default null $l | get $l
}
