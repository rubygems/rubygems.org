class Api::V2::MetricsController < Api::BaseController
  METRICS = %I[
    bundler_version
    rubygems_version
    ruby_version
    ruby_platform
    bundler_command
    ruby_engine
    bundler_settings
    ci_information
  ]
  def create
    METRICS.each do |metric|
      Metriks.counter("#{metric}/#{params[metric]}").increment
    end
  end
end
