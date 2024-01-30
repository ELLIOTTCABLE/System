-- NOTE: dhall-to-toml [doesn't yet support "dynamic records"](dh-2509), so this file currently has to be built with `dhall-to-json` and piped through `yq --toml-output`:
--
-- ```console
-- $ ./Dotfiles/bin/dhall-to-toml-via-yq ./Dotfiles/config/mise/config.dhall
-- ```
--
-- [dh-2509]: <https://github.com/dhall-lang/dhall-haskell/issues/2509>
let Prelude =
      https://prelude.dhall-lang.org/v15.0.0/package.dhall sha256:6b90326dc39ab738d7ed87b970ba675c496bed0194071b332840a87261649dcd

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

let latest-version = \(tool : Text) -> { mapKey = tool, mapValue = "latest" }

let haskell-tools = [ "cabal", "hls" ]

let -- Specify a custom repo url for a given plugin
    -- note this will only be used if the plugin does not already exist
    plugins =
      asdf-ghcup haskell-tools

let tools-to-frontload = [ "nodejs" ]

let tools-to-keep-updated =
      [ "dotnet"
      , "golang"
      , "jq"
      , "lua"
      , "opam"
      , "php"
      , "python"
      , "ruby"
      , "rust"
      ]

let slow-tools = [ "racket", "purescript" ]

let tools =
      Prelude.List.concat
        Text
        [ tools-to-frontload, tools-to-keep-updated, slow-tools ]

let tools =
      Prelude.List.map
        Text
        { mapKey : Text, mapValue : Text }
        latest-version
        tools

in  { plugins, tools }
