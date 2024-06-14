# Pin npm packages by running ./bin/importmap

pin "jquery" # @3.7.1
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "application"
pin_all_from "app/javascript/src", under: "src"

pin "clipboard" # @2.0.11
# stimulus.min.js is a compiled asset from stimulus-rails gem
pin "@hotwired/stimulus", to: "stimulus.min.js"
# stimulus-loading.js is a compiled asset only available from stimulus-rails gem
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# vendored and adapted from https://github.com/mdo/github-buttons/blob/master/src/js.js
pin "github-buttons"
# vendored from github in the before times, not compatible with newest version without changes
pin "webauthn-json"

# Avo custom JS entrypoint
pin "avo.custom", preload: false
pin "stimulus-rails-nested-form", preload: false # @4.1.0
pin "local-time" # @3.0.2
