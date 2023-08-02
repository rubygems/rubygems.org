# frozen_string_literal: true

require "test_helper"

class Maintenance::UserTotpSeedEmptyToNilTaskTest < ActiveSupport::TestCase
  test "#process performs a task iteration" do
    element = create(:user, totp_seed: "")
    Maintenance::UserTotpSeedEmptyToNilTask.process(element)

    assert_nil element.reload.totp_seed

    element = create(:user, :mfa_enabled)
    assert_no_changes -> { element.reload.totp_seed } do
      Maintenance::UserTotpSeedEmptyToNilTask.process(element)
    end
  end

  test "#count returns the number of elements to process" do
    create(:user, totp_seed: "")
    create(:user, :mfa_enabled)

    assert_equal 1, Maintenance::UserTotpSeedEmptyToNilTask.count
  end
end
