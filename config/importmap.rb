# Pin npm packages by running ./bin/importmap

pin "jquery" # @3.7.1
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3-4
pin "application"
pin_all_from "app/javascript/src", under: "src"

pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
# stimulus-loading.js is a compiled asset only available from stimulus-rails gem
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@stimulus-components/clipboard", to: "@stimulus-components--clipboard.js" # @5.0.0
pin "stimulus-rails-nested-form" # @4.1.0
pin "local-time" # @3.0.2

# vendored and adapted from https://github.com/mdo/github-buttons/blob/master/src/js.js
pin "github-buttons"
# vendored from github in the before times, not compatible with newest version without changes
pin "webauthn-json"

# Avo custom JS entrypoint
pin "avo.custom", preload: false
