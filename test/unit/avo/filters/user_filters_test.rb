# frozen_string_literal: true

require "test_helper"

class UserFiltersTest < ActiveSupport::TestCase
  setup do
    @api_key_filter = Avo::Resources::User::ApiKeyNameFilter.new
    @created_at_filter = Avo::Resources::User::CreatedAtFilter.new
  end

  test "API key name filter matches user-owned keys case-insensitively" do
    matching_user = create(:user)
    create(:api_key, owner: matching_user, name: "RECENT-CAMPAIGN-key")
    create(:api_key, owner: matching_user, name: "recent-campaign-second-key")

    create(:api_key, owner: create(:user), name: "unrelated-key")

    user_with_trusted_key_id = create(:user)
    trusted_key = create(:api_key, :trusted_publisher, name: "recent-campaign-key")
    trusted_key.update_column(:owner_id, user_with_trusted_key_id.id)

    result = @api_key_filter.apply(nil, User.all, "recent-campaign")

    assert_equal [matching_user], result.to_a
  end

  test "API key name filter treats SQL wildcard characters literally" do
    matching_user = create(:user)
    create(:api_key, owner: matching_user, name: "campaign-100%-key")
    create(:api_key, owner: create(:user), name: "campaign-1000-key")

    result = @api_key_filter.apply(nil, User.all, "100%")

    assert_equal [matching_user], result.to_a
  end

  test "created at filter includes both ends of the selected range" do
    assert_equal "Account creation time (UTC)", @created_at_filter.name

    start_at = Time.zone.local(2026, 8, 15, 10)
    end_at = Time.zone.local(2026, 8, 15, 12)
    users = [
      create(:user, created_at: start_at),
      create(:user, created_at: end_at)
    ]
    create(:user, created_at: start_at - 1.second)
    create(:user, created_at: end_at + 1.second)

    value = "2026-08-15 10:00:00 to 2026-08-15 12:00:00"
    result = @created_at_filter.apply(nil, User.all, value)

    assert_equal users.sort_by(&:id), result.order(:id).to_a
  end

  test "filters combine to identify users in the campaign and creation window" do
    matching_user = create(:user, created_at: Time.zone.local(2026, 8, 15, 11))
    create(:api_key, owner: matching_user, name: "recent-campaign-key")

    old_user = create(:user, created_at: Time.zone.local(2026, 8, 14, 11))
    create(:api_key, owner: old_user, name: "recent-campaign-key")

    unrelated_user = create(:user, created_at: Time.zone.local(2026, 8, 15, 11))
    create(:api_key, owner: unrelated_user, name: "unrelated-key")

    query = @api_key_filter.apply(nil, User.all, "recent-campaign")
    result = @created_at_filter.apply(nil, query, "2026-08-15 10:00:00 to 2026-08-15 12:00:00")

    assert_equal [matching_user], result.to_a
  end

  test "blank values do not filter users" do
    users = create_list(:user, 2).sort_by(&:id)

    assert_equal users, @api_key_filter.apply(nil, User.all, "").order(:id).to_a
    assert_equal users, @created_at_filter.apply(nil, User.all, "").order(:id).to_a
  end

  test "created at filter fails closed for invalid ranges" do
    create_list(:user, 2)

    invalid_values = [
      "2026-08-15 10:00:00",
      "not a date to 2026-08-15 12:00:00",
      "2026-08-15 12:00:00 to 2026-08-15 10:00:00"
    ]

    invalid_values.each do |value|
      assert_empty @created_at_filter.apply(nil, User.all, value), value
    end
  end
end
