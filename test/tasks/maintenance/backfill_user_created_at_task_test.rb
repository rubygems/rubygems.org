# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillUserCreatedAtTaskTest < ActiveSupport::TestCase
  setup do
    @task = Maintenance::BackfillUserCreatedAtTask.new
  end

  test "#collection includes active and deleted users without created_at" do
    missing_created_at = create(:user)
    missing_created_at.update_column(:created_at, nil)
    create(:user)
    deleted = create(:user)
    deleted.update_columns(created_at: nil, deleted_at: Time.current)

    assert_equal [missing_created_at.id, deleted.id], @task.collection.order(:id).ids
  end

  test "#process backfills created_at and preserves a later value on rerun" do
    user = create(:user)
    user.update_column(:created_at, nil)
    stale_user = @task.collection.find(user.id)
    Maintenance::BackfillUserCreatedAtTask.process(stale_user)

    assert_equal Time.utc(2009, 10, 8, 13, 30, 18), user.reload.created_at

    current_created_at = Time.utc(2020, 1, 2, 3, 4, 5)
    user.update_column(:created_at, current_created_at)

    Maintenance::BackfillUserCreatedAtTask.process(stale_user)

    assert_equal current_created_at, user.reload.created_at
  end

  test "#process backfills a user deleted after being loaded" do
    user = create(:user)
    user.update_column(:created_at, nil)
    user.update_column(:deleted_at, Time.current)

    Maintenance::BackfillUserCreatedAtTask.process(user)

    assert_equal Time.utc(2009, 10, 8, 13, 30, 18), User.with_deleted.find(user.id).created_at
  end
end
