class ReindexRubygemJob < ApplicationJob
  queue_as :default

  def perform(rubygem:)
    rubygem.reindex
  end
end
