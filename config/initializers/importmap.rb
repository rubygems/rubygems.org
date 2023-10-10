Rails.application.configure do
  config.importmap.cache_sweepers << Rails.application.root.join("app/assets/javascripts")
end
