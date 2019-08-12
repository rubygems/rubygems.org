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
    return unless params[:_json]

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
      params[:_json][idx].delete_if { |key, val| key == "command" && val.length > 9 }
    end
  end

  def validate_ruby_bundler_version(idx)
    params[:_json][idx].delete_if do |key, val|
      key == "bundler_version" && !val.match?(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/) ||
        key == "rubygems_version" && !val.match?(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/) ||
        key == "ruby_version" && !val.match?(/\d\.\d{1,2}\.{0,1}\d{0,1}\.{0,1}(preview|pre){0,1}\.{0,1}\d{0,1}/)
    end
  end

  def validate_env_managers(idx)
    params[:_json][idx].delete_if do |key, val|
      key == "git_version" && !val.match?(/([0-9].){1,4}([\w]*)/) ||
        key == "rvm_version" && !val.match?(/([0-9].){1,4}([\w]*)/) ||
        key == "rbenv_version" && !val.match?(/([0-9].){1,4}([\w]*)/) ||
        key == "chruby_version" && !val.match?(/([0-9].){1,4}([\w]*)/)
    end
  end

  def known_id?(id)
    return false unless id
    return true if Rails.cache.read(id)

    Rails.cache.write(id, true, expires_in: 120)
    false
  end
end
