# frozen_string_literal: true

# Copy of each gem's most recent version summary, full-text indexed for
# DatabaseSearcher. Kept in step with OpenSearch by ReindexRubygemJob, which
# indexes the same value (Rubygem#search_data).
class RubygemSearchSummary < ApplicationRecord
  belongs_to :rubygem

  def self.refresh!(rubygem)
    upsert({ rubygem_id: rubygem.id, summary: rubygem.most_recent_version&.summary }, unique_by: :rubygem_id)
  end
end
