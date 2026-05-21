# frozen_string_literal: true

require "test_helper"

class YankRubygemsForUserJobTest < ActiveJob::TestCase
  test "yanks all versions for all of the user's rubygems" do
    user = create(:user)
    rubygems = create_list(:rubygem, 3, owners: [user])

    freeze_time do
      YankRubygemsForUserJob.perform_now(user: user)

      rubygems.each_with_index do |rubygem, index|
        assert_enqueued_with(
          job: YankRubygemJob,
          args: [rubygem: rubygem],
          at: (index * 2.seconds).from_now
        )
      end

      assert_enqueued_jobs 3, only: YankRubygemJob
    end
  end

  test "handles user with no rubygems" do
    user = create(:user)

    assert_nothing_raised do
      YankRubygemsForUserJob.perform_now(user: user)
    end

    assert_enqueued_jobs 0, only: YankRubygemJob
  end
end
