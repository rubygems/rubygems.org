# frozen_string_literal: true

class GemCachePurger
  def self.call(gem_name)
    GemInfo::VERSIONS.each_value do |config|
      Rails.cache.delete("#{config.fetch(:cache_prefix)}/#{gem_name}")
    end
    Rails.cache.delete("names")

    ["info/#{gem_name}", "names"].each do |path|
      FastlyPurgeJob.perform_later(path:, soft: true)
    end

    FastlyPurgeJob.perform_later(path: "versions", soft: true)
    FastlyPurgeJob.perform_later(path: "gem/#{gem_name}", soft: true)
    FastlyPurgeJob.perform_later(key: "gem/#{gem_name}", soft: true)
    FastlyPurgeJob.perform_later(key: "api/v1/activities", soft: true)
  end
end
