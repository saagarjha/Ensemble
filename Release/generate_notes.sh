#!/bin/sh

LAST_TAG="$(git tag --sort=-version:refname | head -2 | tail -n 1)"
git log "$LAST_TAG"..HEAD --pretty=format:"[%as] %h: %s (%aN <%aE>)"
