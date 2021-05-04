#!/usr/bin/env bash

set -Eeuo pipefail

export RBENV_VERSION=2.7.2

RUBYLIB="ruml" \
  RUML_GROUP_BY_GLOB="ruml/test/*" \
  RUML_APP_GLOB="ruml/test/*" \
  ruby -r ruml fixture.rb
