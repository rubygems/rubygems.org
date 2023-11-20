# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillApiKeyOwnersTaskTest < ActiveSupport::TestCase
  test "#process performs a task iteration" do
    element = create(:api_key)
    element.update_columns(owner_id: nil, owner_type: nil)

    assert_nil element.reload.owner

    Maintenance::BackfillApiKeyOwnersTask.process(element)

    assert_equal element.reload.user, element.owner
  end

  test "#collection returns the elements to process" do
    create(:api_key)
    nil_owner = create(:api_key, key: "other")
    nil_owner.update_columns(owner_id: nil, owner_type: nil)

    assert_nil nil_owner.reload.owner
    assert_same_elements [nil_owner], Maintenance::BackfillApiKeyOwnersTask.collection
  end
end
