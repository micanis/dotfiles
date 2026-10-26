#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title devbox: go
# @raycast.mode silent
# @raycast.packageName devbox
# @raycast.icon 📦
# @raycast.description Copy the nushell command that sets up devbox + direnv with the go plugin

printf '%s' '{packages: [], include: ["github:micanis/dotfiles?dir=devbox-plugin/go"]} | save -f devbox.json; devbox generate direnv' | pbcopy
echo "Copied devbox (go) setup command"
