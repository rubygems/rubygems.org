class Api::MetricsController < Api::BaseController
  METRIC_KEYS = %i[
    host
    ruby_version
    bundler_version
    rubygems_version
    ruby_engine
    command
    git_version
    rvm_version
    rbenv_version
    chruby_version
  ].freeze

  def create
    head :ok && return if known_id?(params[:request_id])

    METRIC_KEYS.each do |metric|
      StatsD.increment("#{metric}.#{params[metric]}") if params[metric]
    end
    split_increment("options", params[:options]) if params[:options]
    split_increment("ci", params[:ci]) if params[:ci]
  end

  def split_increment(type, comma_string)
    comma_string.split(",").each { |val| StatsD.increment("#{type}.#{val}") }
  end

  def known_id?(id)
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
