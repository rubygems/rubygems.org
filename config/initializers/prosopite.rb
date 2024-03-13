if Rails.env.local?
  require 'prosopite/middleware/rack'
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)

  Rails.application.config.after_initialize do
    Prosopite.rails_logger = true
    Prosopite.raise = true
    Prosopite.ignore_queries = [
      # dependency api intentionally loads 1 by 1, so each gem can be stored in the cache
      # plus the API is deprecated
      Regexp.new(Regexp.quote("SELECT rv.name, rv.number, rv.platform, d.requirements, for_dep_name.name dep_name"))
    ]
    Prosopite.allow_stack_paths = [
      %(app/mailers/)
    ]
  end
end
