# frozen_string_literal: true

class ReindexRubygemJob < ApplicationJob
  queue_as :default

  def perform(rubygem:)
    # Database first, so an OpenSearch outage doesn't leave it stale too
    RubygemSearchSummary.refresh!(rubygem)
    rubygem.reindex
  end
end
