# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  skip "lib/tasks"
  skip "lib/rails_development_log_formatter.rb"

  if ENV["CI"]
    require "simplecov-cobertura"
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end
