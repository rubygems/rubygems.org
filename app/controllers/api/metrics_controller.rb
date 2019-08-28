class Api::MetricsController < Api::BaseController
  # high cardinality metrics are currently uninstrumented
  METRIC_KEYS = %w[
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

  # takes a YAMLed array of metric hashes,
  # and increment Datadog counter for all low cardinality metrics
  def create
    return unless request.raw_post

    require "psych"
    @metrics = Psych.safe_load(request.raw_post)
    # input is at least of length 2, so it must be an array
    return unless @metrics.is_a?(Array)

    # discard data if its a duplicate
    head :ok && return if known_id?(@metrics.last["request_id"])
    validate_data

    @metrics.each do |hash|
      METRIC_KEYS.each do |metric|
        StatsD.increment("#{metric}.#{hash[metric]}") if hash[metric]
      end
      split_increment("options", hash["options"]) if hash["options"]
      split_increment("ci", hash["ci"]) if hash["ci"]
    end
  end

  private

  def split_increment(type, comma_string)
    comma_string.split(",").each do |val|
      StatsD.increment("#{type}.#{val}") if val.length < 20
    end
  end

  def validate_data
    @metrics.delete_if { |ele| !ele.is_a?(Hash) }
    @metrics.each_index do |idx|
      validate_ruby_bundler_version(idx)
      validate_env_managers(idx)
      @metrics[idx].delete_if { |key, val| key == "host" && val.length > 20 }
      @metrics[idx].delete_if { |key, val| key == "command" && val.length > 9 }
    end
  end

  def valid_version?(val)
    Gem::Version::ANCHORED_VERSION_PATTERN.match?(val)
  end

  def validate_ruby_bundler_version(idx)
    @metrics[idx].delete_if do |key, val|
      key == "ruby_version" && !valid_version?(val) ||
        key == "bundler_version" && !valid_version?(val) ||
        key == "rubygems_version" && !valid_version?(val)
    end
  end

  def validate_env_managers(idx)
    @metrics[idx].delete_if do |key, val|
      key == "git_version" && !valid_version?(val) ||
        key == "rvm_version" && !valid_version?(val) ||
        key == "rbenv_version" && !valid_version?(val) ||
        key == "chruby_version" && !valid_version?(val)
    end
  end

  def known_id?(id)
    return false unless id
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
