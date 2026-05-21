# frozen_string_literal: true

class ReindexRubygemJob < ApplicationJob
  queue_as :default

  def perform(rubygem:)
    rubygem.reindex
    rubygem.update_search_vector
  end
end
