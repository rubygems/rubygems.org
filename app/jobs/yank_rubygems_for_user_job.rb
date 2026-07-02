# frozen_string_literal: true

class YankRubygemsForUserJob < ApplicationJob
  STAGGER_INTERVAL = 2.seconds

  queue_as :default
  queue_with_priority PRIORITIES.fetch(:push)

  def perform(user:)
    user.rubygems.find_each.with_index do |rubygem, index|
      YankRubygemJob.set(wait: index * STAGGER_INTERVAL).perform_later(rubygem: rubygem)
    end
  end
end
