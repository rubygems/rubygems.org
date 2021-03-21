# ignore rake tasks because don't need to autoload them
Rails.autoloaders.main.ignore(Rails.root.join("lib/tasks"))

# does not require autoload. ignore SqsWorker to supress following:
# expected file lib/shoryuken/sqs_worker.rb to define constant Shoryuken::SqsWorker
Rails.autoloaders.main.ignore(Rails.root.join("lib/shoryuken"))
