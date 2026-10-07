# frozen_string_literal: true

require "test_helper"

class Maintenance::ClearLegacyEmailConfirmationTokensTaskTest < ActiveSupport::TestCase
  setup do
    @task = Maintenance::ClearLegacyEmailConfirmationTokensTask.new
  end

  test "#collection includes active and deleted users with either legacy column set" do
    token_only = create(:user)
    token_only.update_columns(confirmation_token: "legacy")
    expiry_only = create(:user)
    expiry_only.update_columns(token_expires_at: 1.day.ago)
    deleted = create(:user)
    deleted.update_columns(confirmation_token: "legacy", token_expires_at: 1.day.from_now, deleted_at: Time.current)
    create(:user)

    assert_equal [token_only, expiry_only, deleted].map(&:id).sort, @task.collection.ids.sort
  end

  test "#process clears only the legacy columns and is safe to rerun" do
    user = create(:user)
    reset_token = user.issue_password_reset!
    user.update_columns(confirmation_token: "legacy", token_expires_at: 1.day.from_now)
    loaded = @task.collection.find(user.id)

    2.times { Maintenance::ClearLegacyEmailConfirmationTokensTask.process(loaded) }

    user.reload

    assert_nil user.confirmation_token
    assert_nil user.token_expires_at
    assert user.valid_password_reset_token?(reset_token)
  end

  test "#process does not touch other users" do
    user = create(:user)
    user.update_columns(confirmation_token: "legacy")
    other = create(:user)
    other.update_columns(confirmation_token: "other", token_expires_at: 1.day.from_now)

    Maintenance::ClearLegacyEmailConfirmationTokensTask.process(user)

    assert_equal "other", other.reload.confirmation_token
    refute_nil other.token_expires_at
  end
end
