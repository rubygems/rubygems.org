# frozen_string_literal: true

require "test_helper"

class ReindexRubygemJobTest < ActiveJob::TestCase
  should "refresh the search summary even when OpenSearch is unavailable" do
    rubygem = create(:rubygem)
    create(:version, rubygem:, summary: "Classy web development")
    rubygem.stubs(:reindex).raises(Faraday::ConnectionFailed, "down")

    assert_enqueued_with(job: ReindexRubygemJob) { ReindexRubygemJob.perform_now(rubygem:) } # retried later

    assert_equal "Classy web development", rubygem.reload.search_summary.summary
  end
end
