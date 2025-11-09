Rails.autoloaders.main.on_load("Blazer::BaseController") do
  Blazer::BaseController.include GitHubOAuthable
end
