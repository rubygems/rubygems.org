# ignore rake tasks because don't need to autoload them
Rails.autoloaders.main.ignore(Rails.root.join("lib/tasks"))

# does not require autoload. ignore SqsWorker to supress following:
# expected file lib/shoryuken/sqs_worker.rb to define constant Shoryuken::SqsWorker
Rails.autoloaders.main.ignore(Rails.root.join("lib/shoryuken"))

Rails.autoloaders.main.ignore(Rails.root.join("lib/cops"))

Rails.autoloaders.main.ignore(Rails.root.join("lib/puma/plugin"))

unless defined?(Avo::Pro)
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/cards"))
  Rails.autoloaders.main.ignore(Rails.root.join("app/avo/dashboards"))
  Rails.autoloaders.main.ignore(Rails.root.join("lib/admin/authorization_client.rb"))
end

Rails.autoloaders.once.inflector.inflect(
  "http" => "HTTP",
  "oidc" => "OIDC"
)
