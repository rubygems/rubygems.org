# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin_all_from "app/javascript/src", under: "src"

# vendored and adapted from https://github.com/mdo/github-buttons/blob/master/src/js.js
pin "github-buttons"
# vendored from github in the before times
pin "webauthn-json"

pin "jquery" # @3.7.1
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "clipboard" # @2.0.11
