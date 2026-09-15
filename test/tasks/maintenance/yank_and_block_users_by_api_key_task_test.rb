# frozen_string_literal: true

require "test_helper"

class Maintenance::YankAndBlockUsersByApiKeyTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @task = Maintenance::YankAndBlockUsersByApiKeyTask.new
    @task.api_key_name = "key-to-remove"
  end

  context "#collection" do
    should "include users with a recently created matching API key" do
      user = create(:user)
      create(:api_key, owner: user, name: "key-to-remove", created_at: 1.hour.ago)

      assert_includes @task.collection, user
    end

    should "match API key name case-insensitively" do
      user = create(:user)
      create(:api_key, owner: user, name: "KEY-TO-REMOVE-123", created_at: 1.hour.ago)

      assert_includes @task.collection, user
    end

    should "exclude users whose matching API key is outside the time window" do
      user = create(:user)
      create(:api_key, owner: user, name: "key-to-remove", created_at: 2.days.ago)

      assert_not_includes @task.collection, user
    end

    should "exclude users without a matching API key name" do
      user = create(:user)
      create(:api_key, owner: user, name: "ci-key", created_at: 1.hour.ago)

      assert_not_includes @task.collection, user
    end

    should "exclude already blocked users" do
      user = create(:user, :blocked)
      create(:api_key, owner: user, name: "key-to-remove", created_at: 1.hour.ago)

      assert_not_includes @task.collection, user
    end

    should "exclude discarded users" do
      user = create(:user)
      user.discard!
      create(:api_key, owner: user, name: "key-to-remove", created_at: 1.hour.ago)

      assert_not_includes @task.collection, user
    end

    should "exclude users whose matching key is not user-owned" do
      user = create(:user)
      trusted_key = create(:api_key, :trusted_publisher, name: "key-to-remove", created_at: 1.hour.ago)
      trusted_key.update_column(:owner_id, user.id)

      assert_not_includes @task.collection, user
    end

    should "deduplicate users with multiple matching API keys" do
      user = create(:user)
      create(:api_key, owner: user, name: "key-to-remove-one", created_at: 1.hour.ago)
      create(:api_key, owner: user, name: "key-to-remove-two", created_at: 1.hour.ago)

      assert_equal [user], @task.collection.to_a
    end

    should "honor a custom created_within_hours window" do
      @task.created_within_hours = 48
      user = create(:user)
      create(:api_key, owner: user, name: "key-to-remove", created_at: 30.hours.ago)

      assert_includes @task.collection, user
    end
  end

  context "#collection user id bounds" do
    setup do
      @users = create_list(:user, 3).sort_by(&:id)
      @users.each do |user|
        create(:api_key, owner: user, name: "key-to-remove", created_at: 1.hour.ago)
      end
    end

    should "apply min_user_id as an inclusive lower bound" do
      @task.min_user_id = @users[1].id

      assert_equal @users[1..], @task.collection.order(:id).to_a
    end

    should "apply max_user_id as an inclusive upper bound" do
      @task.max_user_id = @users[1].id

      assert_equal @users[0..1], @task.collection.order(:id).to_a
    end

    should "be invalid when max_user_id is below min_user_id" do
      @task.min_user_id = 10
      @task.max_user_id = 5

      refute_predicate @task, :valid?
      assert_includes @task.errors[:max_user_id], "must be greater than or equal to min_user_id"
    end
  end

  context "#process" do
    should "enqueue a yank job and block the user" do
      user = create(:user)

      assert_enqueued_jobs(1, only: YankRubygemsForUserJob) do
        @task.process(user)
      end

      assert_predicate user.reload, :blocked?
    end

    should "skip already blocked users" do
      user = create(:user, :blocked)

      assert_no_enqueued_jobs(only: YankRubygemsForUserJob) do
        @task.process(user)
      end
    end

    should "skip discarded users" do
      user = create(:user)
      user.discard!

      assert_no_enqueued_jobs(only: YankRubygemsForUserJob) do
        @task.process(user)
      end

      assert_not user.reload.blocked?
    end

    should "report and swallow ActiveRecord failures without raising" do
      user = create(:user)
      User.any_instance.expects(:block!).raises(ActiveRecord::RecordNotSaved)

      assert_error_reported(ActiveRecord::RecordNotSaved) do
        assert_nothing_raised { @task.process(user) }
      end
      assert_not user.reload.blocked?
    end
  end

  context "validations" do
    should "require api_key_name" do
      task = Maintenance::YankAndBlockUsersByApiKeyTask.new

      refute_predicate task, :valid?
      assert_includes task.errors[:api_key_name], "can't be blank"
    end

    should "require a positive created_within_hours" do
      @task.created_within_hours = 0

      refute_predicate @task, :valid?
      assert_includes @task.errors[:created_within_hours], "must be greater than 0"
    end
  end
end
