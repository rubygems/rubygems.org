# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillRubygemSearchSummariesTaskTest < ActiveSupport::TestCase
  should "backfill only gems missing a summary row, without overwriting newer summaries" do
    missing = create(:rubygem)
    create(:version, rubygem: missing, summary: "Pushed before the table existed")
    present = create(:rubygem)
    RubygemSearchSummary.refresh!(present)

    assert_equal [missing], Maintenance::BackfillRubygemSearchSummariesTask.collection.to_a

    loaded = Maintenance::BackfillRubygemSearchSummariesTask.collection.first
    create(:version, rubygem: missing, number: "2.0.0", summary: "Pushed while the task ran")
    Maintenance::BackfillRubygemSearchSummariesTask.process(loaded)

    assert_equal "Pushed while the task ran", missing.reload.search_summary.summary
    assert_empty Maintenance::BackfillRubygemSearchSummariesTask.collection
  end
end
