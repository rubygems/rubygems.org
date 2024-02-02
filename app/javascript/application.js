// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import Rails from "@rails/ujs";
Rails.start();
import "controllers"

import "src/api_key_form";
import "src/autocomplete";
import "src/clipboard_buttons";
import "src/multifactor_auths";
import "src/oidc_api_key_role_form";
import "src/pages";
import "src/search";
import "src/transitive_dependencies";
import "src/webauthn";
import "github-buttons";
