# frozen_string_literal: true

require "test_helper"

class RubygemSearchSummaryTest < ActiveSupport::TestCase
  context ".refresh!" do
    setup do
      @rubygem = create(:rubygem)
    end

    should "store the most recent version's summary and update it on later refreshes" do
      create(:version, rubygem: @rubygem, number: "1.0.0", summary: "Old summary")
      RubygemSearchSummary.refresh!(@rubygem)

      assert_equal "Old summary", @rubygem.reload.search_summary.summary

      create(:version, rubygem: @rubygem, number: "2.0.0", summary: "New summary")
      RubygemSearchSummary.refresh!(@rubygem.reload)

      assert_equal 1, RubygemSearchSummary.where(rubygem: @rubygem).count
      assert_equal "New summary", @rubygem.reload.search_summary.summary
    end

    should "store no summary for a gem without versions" do
      RubygemSearchSummary.refresh!(@rubygem)

      assert_nil @rubygem.reload.search_summary.summary
    end
  end
end
