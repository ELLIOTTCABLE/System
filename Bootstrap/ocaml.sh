#!/usr/bin/env dash

SCRIPTPATH=$(dirname "$0")
export OPAMYES='true' OPAMBUILDDOC='true'

set -ex
opam init --bare --no-setup

opam switch create default ocaml-base-compiler

# Unfortunately, opam [isn't interested in fixing this](https://github.com/ocaml/opam/issues/3512).
# Have to manually add a *non-default path* to a ‘_globals’ switch, if I want to be able to install
# “global binaries” with opam (like `ocamlformat` or `patdiff`.)
#
# The name '_globals' is chosen pretty much at random. Make sure to mirror it in Dotfiles/shenv!
opam switch create _globals --empty --no-switch \
  --description="System-global binaries"

opam install --working-dir --deps-only --set-root --best-effort \
  --switch=_globals \
  "$SCRIPTPATH/../Dotfiles/opam/default-packages/default-packages.opam"
