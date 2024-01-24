require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  def all_records
    ApplicationRecord.descendants.reject(&:abstract_class?).sort_by(&:name).to_h do |record_class|
      [record_class.name, record_class.order(:id).map(&:attributes).as_json]
    end
  end

  def load_seed
    capture_io { Rails.application.load_seed }
  end

  test "can load seeds idempotently" do
    load_seed

    assert_no_changes "all_records" do
      load_seed
    end
  end
end
