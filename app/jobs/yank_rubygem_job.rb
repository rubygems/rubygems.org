# frozen_string_literal: true

class YankRubygemJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:push)

  def perform(rubygem:)
    rubygem.yank_versions!(force: true)
  end
end
