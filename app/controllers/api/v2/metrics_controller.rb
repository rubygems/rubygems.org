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





=begin

bundler version
- rubygems version
- ruby version
- ruby platform/host
- bundler command being run
- ruby engine and engine version (e.g. JRuby, Rubinius)
- Bundler settings that have been set (keys only, not values)
- CI information (is bundler running on a CI platform)


=end
