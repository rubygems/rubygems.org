# frozen_string_literal: true

Rails.autoloaders.main.on_load("Blazer::BaseController") do
  Blazer::BaseController.include GitHubOAuthable
end
