-- NOTE: dhall-to-toml [doesn't yet support "dynamic records"](dh-2509), so this file currently has to be built with `dhall-to-json` and piped through `yq --toml-output`:
--
-- ```console
-- ./Dotfiles/bin/dhall-to-toml-via-yq ./Dotfiles/config/mise/config.dhall \
--    >./Dotfiles/config/mise/config.toml
-- ```
--
-- [dh-2509]: <https://github.com/dhall-lang/dhall-haskell/issues/2509>
let Prelude =
      https://prelude.dhall-lang.org/v15.0.0/package.dhall
        sha256:6b90326dc39ab738d7ed87b970ba675c496bed0194071b332840a87261649dcd

let -- Most tools track `latest` as a bare string, but a few (rust, lua,
    -- claude-code) need an table for mise tool options like `os`, `components`,
    -- or per-platform `url`s. That heterogeneity is exactly the "dynamic
    -- records" case from the note above, so every tool value is built as
    -- `JSON.Type`; `str`/`field` are thin aliases that keep those literals
    -- legible.
    json =
      Prelude.JSON

let str = json.string

let field =
      \(key : Text) ->
      \(value : json.Type) ->
        { mapKey = key, mapValue = value }

let -- Generates a plugin map for the given tools that asdf-ghcup can install
    asdf-ghcup =
      Prelude.List.map
        Text
        { mapKey : Text, mapValue : Text }
        ( \(tool : Text) ->
            { mapKey = tool
            , mapValue = "https://github.com/sestrella/asdf-ghcup.git"
            }
        )

let latest-version = \(tool : Text) -> field tool (str "latest")

let haskell-tools = [ "cabal", "hls" ]

let -- Specify a custom repo url for a given plugin
    -- note this will only be used if the plugin does not already exist
    plugins =
      asdf-ghcup haskell-tools

let tools-to-frontload = [ "nodejs" ]

let tools-to-keep-updated =
      [ "bun"
      , "cargo-binstall"
      , "deno"
      , "dotnet"
      , "github:joevt/AllRez"
      , "go"
      , "ruby"
      , "usage"
      , "uv"
      , "yamlfmt"
      ]

let slow-tools = [ "purescript" ]

let -- fd and hk stopped publishing x86_64-apple-darwin binaries; Intel macs
    -- build from crates.io instead (whose crate name can differ: fd → fd-find)
    cargo-on-intel-mac =
      \(tool : Text) ->
      \(crate : Text) ->
        [ field
            tool
            ( json.object
                [ field "version" (str "latest")
                , field
                    "os"
                    ( json.array
                        [ str "windows", str "linux", str "darwin/arm64" ]
                    )
                ]
            )
        , field
            "cargo:${crate}"
            ( json.object
                [ field "version" (str "latest")
                , field "os" (json.array [ str "darwin/amd64" ])
                ]
            )
        ]

let claude-base =
      "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

let claude-windows =
      json.object
        [ field "bin" (str "claude.exe")
        , field "url" (str "${claude-base}/{{ version }}/win32-x64/claude.exe")
        ]

let -- Tools whose mise config is a table rather than a bare version
    structured-tools =
      [ field
          "rust"
          ( json.object
              [ field "version" (str "stable")
              , field "components" (str "rust-src,rust-analyzer")
              ]
          )
      , field
          "lua"
          ( json.object
              [ field "version" (str "latest")
              , field "os" (json.array [ str "linux", str "macos" ])
              ]
          )
      , field
          "opam"
          ( json.object
              [ field "version" (str "latest")
              , field "os" (json.array [ str "linux", str "macos" ])
              ]
          )
      , field
          "claude-code"
          ( json.object
              [ field "version" (str "latest")
              , field "bin" (str "claude")
              , field
                  "platforms"
                  (json.object [ field "windows-x64" claude-windows ])
              , field
                  "url"
                  ( str
                      "${claude-base}/{{ version }}/{{ os(macos=\"darwin\") }}-{{ arch() }}/claude"
                  )
              , field "version_list_url" (str "${claude-base}/latest")
              ]
          )
      ]

let simple-tools =
      Prelude.List.map
        Text
        { mapKey : Text, mapValue : json.Type }
        latest-version
        ( Prelude.List.concat
            Text
            [ tools-to-frontload, tools-to-keep-updated, slow-tools ]
        )

let tools =
      json.object
        (   simple-tools
          # structured-tools
          # cargo-on-intel-mac "hk" "hk"
          # cargo-on-intel-mac "fd" "fd-find"
        )

let xdg-config = "{{ get_env(name='XDG_CONFIG_HOME', default='~/.config') }}"

let env =
      { MISE_NODE_DEFAULT_PACKAGES_FILE =
          "${xdg-config}/mise/default-npm-packages"
      }

let settings =
      { idiomatic_version_file_enable_tools = [ "ruby" ]
      , python =
        { default_packages_file = "${xdg-config}/mise/default-pip-packages"
        , compile = True
        }
      }

in  { plugins, tools, env, settings }
