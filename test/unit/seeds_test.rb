require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  def load_seed
    capture_io { Rails.application.load_seed }
  end

  test "can load seeds idempotently" do
    load_seed

    assert_no_changes -> { ApplicationRecord.descendants.map { |d| [d.name, d.all.map(&:attributes)] } } do
      load_seed
    end
  end
end
