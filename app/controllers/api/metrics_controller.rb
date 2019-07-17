class Api::MetricsController < Api::BaseController
  METRIC_KEYS = %i[
    host
    ruby_version
    bundler_version
    rubygems_version
    ruby_engine
    command
    options
    git_version
    rvm_version
    rbenv_version
    chruby_version
    ci
    extra_ua
  ].freeze

  def create
    head :ok && return if known_id?(params[:request_id])

    METRIC_KEYS.each do |metric|
      StatsD.increment(params[metric], tags=[metric]) if params[metric]
    end

  end

  def known_id?(id)
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
