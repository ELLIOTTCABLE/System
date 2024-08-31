-- NOTE: dhall-to-toml [doesn't yet support "dynamic records"](dh-2509), so this file currently has to be built with `dhall-to-json` and piped through `yq --toml-output`:
--
-- ```console
-- $ ./Dotfiles/bin/dhall-to-toml-via-yq ./Dotfiles/config/mise/config.dhall
-- ```
--
-- [dh-2509]: <https://github.com/dhall-lang/dhall-haskell/issues/2509>
let Prelude =
      https://prelude.dhall-lang.org/v15.0.0/package.dhall
        sha256:6b90326dc39ab738d7ed87b970ba675c496bed0194071b332840a87261649dcd

let GitSrc =
      { Type =
          { repo : Text
          , at : Optional < Branch : Text | Tag : Text | Rev : Text >
          }
      , default.at = None < Branch : Text | Tag : Text | Rev : Text >
      }

let Source = < GitHub : GitSrc.Type | Gist : GitSrc.Type | Git : GitSrc.Type >

let PluginConfig =
      { Type = { source : Source, use : Optional (List Text) }
      , default.use = None (List Text)
      }

let Plugin =
      { Type = { name : Text, config : PluginConfig.Type }
      , default = { name = "UNKNOWN", config = PluginConfig.default }
      }

let github-named =
      \(name : Text) ->
      \(slug : Text) ->
        Plugin::{
        , name = name
        , config = PluginConfig::{
          , source = Source.GitHub GitSrc::{ repo = slug }
          }
        }

let github =
      \(user : Text) -> \(repo : Text) -> github-named repo "${user}/${repo}"

let plugins =
      [ github "mafredri" "zsh-async"
      ,     github "sindresorhus" "pure"
   --   //  Plugin::{ config = PluginConfig::{ use = Some [ "pure.zsh" ] } }
      , github "zsh-users" "zsh-autosuggestions"
      ]

-- this isn't functional yet; i'm bad at Dhall

let plugins =
      Prelude.List.map Plugin.Type {} (\(plugin : Plugin.Type) ->
      in
      {
      , mapKey = plugin.name
      , mapValue = plugin.config
      } : { mapKey : Text, mapValue : {
      , github: Optional Text
      , gist: Optional Text
      , git: Optional Text
      }}) plugins

in  { plugins }
