class Api::V1::MetricsController < Api::BaseController
  METRIC_KEYS = %i[
    bundler
    rubygems
    ruby
    arch
    command
  ].freeze

  def create
    head :ok && return if known_id?(params[:id])

    METRIC_KEYS.each do |metric|
      StatsD.increment "#{metric}.#{params[metric]}" if params[metric]
    end

    StatsD.increment ruby_engine_metric if params[:ruby_engine]
    split_increment("option", params[:options]) if params[:options]
    split_increment("ci", params[:ci]) if params[:ci]
    head :ok
  end

  private

  def split_increment(type, comma_string)
    comma_string.split(",").each { |k| StatsD.increment("#{type}.#{k}") }
  end

  def ruby_engine_metric
    "ruby_engine.#{params[:ruby_engine]}.#{params[:ruby_engine_version]}"
  end

  def known_id?(id)
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
