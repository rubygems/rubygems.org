# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillApiKeyScopesTaskTest < ActiveSupport::TestCase
  test "#collection returns all ApiKeys" do
    assert_equal ApiKey.all, Maintenance::BackfillApiKeyScopesTask.collection
  end

  test "#process performs a task iteration" do
    element = create(:api_key)
    element.update_attribute!(:scopes, nil)
    Maintenance::BackfillApiKeyScopesTask.process(element)

    assert_equal %i[index_rubygems], element.scopes
    assert_equal element.enabled_scopes, element.scopes
  end

  test "#process ignores keys with scopes already set" do
    element = create(:api_key)
    assert_no_changes -> { element.updated_at } do
      Maintenance::BackfillApiKeyScopesTask.process(element)
    end
  end
end
