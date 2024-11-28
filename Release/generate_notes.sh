#!/bin/sh

set -x

# I'd like to use HEAD, but alas: https://github.com/actions/checkout/issues/969
LAST_TAG="$(git tag --sort=-version:refname | head -2 | tail -n 1)"
CURRENT_TAG="$(git tag --sort=-version:refname | head -1)"
git log "$LAST_TAG"..main --pretty=format:"[%as] %h: %s (%aN <%aE>)"
