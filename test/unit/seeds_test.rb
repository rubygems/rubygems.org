require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "can load seeds idempotently" do
    Rails.application.load_seed

    assert_no_changes -> { ApplicationRecord.descendants.map { |d| [d.name, d.all.map(&:attributes)] } } do
      Rails.application.load_seed
    end
  end
end
