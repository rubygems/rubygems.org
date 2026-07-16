# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillHistoricalOwnershipsTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return ownerships between min_ownership_id and max_ownership_id" do
      ownership1 = create(:ownership)
      ownership2 = create(:ownership)
      create(:ownership)

      task = Maintenance::BackfillHistoricalOwnershipsTask.new
      task.min_ownership_id = ownership1.id
      task.max_ownership_id = ownership2.id

      assert_equal [ownership1, ownership2], task.collection.to_a
    end
  end

  context "#process" do
    should "create a matching open HistoricalOwnership when none exists" do
      ownership = create(:ownership, role: :owner)
      HistoricalOwnership.where(rubygem: ownership.rubygem, user: ownership.user).delete_all

      Maintenance::BackfillHistoricalOwnershipsTask.new.process(ownership)

      historical = HistoricalOwnership.find_by(rubygem: ownership.rubygem, user: ownership.user)

      assert_predicate historical, :present?
      assert_nil historical.removed_at
      assert_equal "owner", historical.role
      assert_equal ownership.created_at, historical.first_owned_at
    end

    should "not create a duplicate when an open HistoricalOwnership already exists" do
      ownership = create(:ownership)

      assert_no_difference "HistoricalOwnership.count" do
        Maintenance::BackfillHistoricalOwnershipsTask.new.process(ownership)
      end
    end
  end
end
