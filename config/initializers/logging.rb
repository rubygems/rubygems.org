formatter =  ::ActiveSupport::Logger::SimpleFormatter.new
formatter.extend ::ActiveSupport::TaggedLogging::Formatter

Rails.logger.formatter = formatter
