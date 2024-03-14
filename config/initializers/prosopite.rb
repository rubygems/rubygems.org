if Rails.env.local?
  require 'prosopite/middleware/rack'
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)

  Rails.application.config.after_initialize do
    Prosopite.custom_logger = SemanticLogger[Prosopite]
    Prosopite.raise = true
    Prosopite.ignore_queries = []
    Prosopite.allow_stack_paths = [
      # mailers need refactoring to not find based on IDs when we already have objects in memory
      "app/mailers/",

      # avo auditing potentially loads things multiple times, but it will be bounded by the size of the audit
      "app/avo/actions/base_action.rb",
      "app/components/avo/fields/audited_changes_field/show_component.html.erb",

      # calls count for each owner, AR doesn't yet allow preloading aggregates
      "app/views/ownership_requests/_ownership_request.html.erb"
    ]
  end
end
