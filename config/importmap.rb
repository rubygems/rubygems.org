# Pin npm packages by running ./bin/importmap

pin_all_from "app/assets/javascripts", preload: true
pin "github-buttons"

pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.0/dist/jquery.js"
pin "jquery-ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.8/lib/assets/compiled/rails-ujs.js"
pin "clipboard", to: "https://ga.jspm.io/npm:clipboard@2.0.11/dist/clipboard.js"
pin "@github/webauthn-json/browser-ponyfill", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.browser-ponyfill.js"
