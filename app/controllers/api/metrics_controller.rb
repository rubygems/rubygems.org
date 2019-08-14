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
    return unless params.require(:_json)

    validate_data
    if params[:_json].last
      head :ok && return if known_id?(params[:_json].last[:request_id])
    end

    params[:_json].each do |hash|
      METRIC_KEYS.each do |metric|
        StatsD.increment("#{metric}.#{hash[metric]}") if hash[metric]
      end
      split_increment("options", hash[:options]) if hash[:options]
      split_increment("ci", hash[:ci]) if hash[:ci]
    end
  end

  private

  def split_increment(type, comma_string)
    comma_string.split(",").each do |val|
      StatsD.increment("#{type}.#{val}") if val.length < 20
    end
  end

  def validate_data
    params[:_json].each_index do |idx|
      validate_ruby_bundler_version(idx)
      validate_env_managers(idx)
      params[:_json][idx].delete_if { |key, val| key == "host" && val.length > 20 }
      params[:_json][idx].delete_if { |key, val| key == "command" && val.length > 9 }
    end
  end

  def validate_ruby_bundler_version(idx)
    params[:_json][idx].delete_if do |key, val|
      key == "bundler_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val) ||
        key == "rubygems_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val) ||
        key == "ruby_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val)
    end
  end

  def validate_env_managers(idx)
    params[:_json][idx].delete_if do |key, val|
      key == "git_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val) ||
        key == "rvm_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val) ||
        key == "rbenv_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val) ||
        key == "chruby_version" && !Gem::Version::ANCHORED_VERSION_PATTERN.match?(val)
    end
  end

  def known_id?(id)
    return false unless id
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
