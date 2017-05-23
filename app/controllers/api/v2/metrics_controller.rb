class Api::V2::MetricsController < Api::BaseController
  METRICS = %I[
    bundler
    rubygems
    ruby
    ruby_platform
    bundler
    ruby_engine
    options
    ci
  ].freeze


  def create
    if params[:ruby_engine] && params[:ruby_engine_version]
      StatsD.increment("#{params[:ruby_engine]}/#{params[:ruby_engine_version]}")
    end

    METRICS.each do |metric|
      if params[metric]
        StatsD.increment("#{metric}/#{params[metric]}")
      end
    end
    head :ok
  end
end

#
