# Pin npm packages by running ./bin/importmap

pin "jquery" # @3.7.1
pin "application", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "clipboard" # @2.0.11
pin "github_buttons" # vendored originally
pin "webauthn-json" # vendored originally
