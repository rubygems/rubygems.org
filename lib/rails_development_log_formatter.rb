class RailsDevelopmentLogFormatter < SemanticLogger::Formatters::Color
  def call(log, logger)
    self.color  = Rails.configuration.colorize_logging ? color_map[log.level] : Hash.new("")
    self.log    = log
    self.logger = logger

    [tags, named_tags, message, payload, exception].compact.join(" ")
  end

  # Log message
  delegate :message, to: :log
end
