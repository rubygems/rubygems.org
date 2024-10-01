// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import Rails from "@rails/ujs";
Rails.start();

import LocalTime from "local-time"
LocalTime.start()

import "controllers"

import "src/oidc_api_key_role_form";
import "src/pages";
import "src/transitive_dependencies";
import "src/webauthn";
import "github-buttons";
