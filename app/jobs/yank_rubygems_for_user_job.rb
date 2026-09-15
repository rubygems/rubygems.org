# frozen_string_literal: true

class YankRubygemsForUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:push)

  def perform(user:)
    user.rubygems.find_each do |rubygem|
      rubygem.yank_versions!(force: true)
    end
  end
end
