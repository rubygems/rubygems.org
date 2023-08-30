# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillUserPublicEmailTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return users" do
      u = create(:user)

      assert_kind_of ActiveRecord::Batches::BatchEnumerator, Maintenance::BackfillUserPublicEmailTask.collection
      assert_equal u, Maintenance::BackfillUserPublicEmailTask.collection.each_record.first
    end
  end

  context "#process" do
    should "updates public_email to opposite of hide_email" do
      user_with_hidden_email = create(:user, hide_email: true)
      user_with_public_email = create(:user, hide_email: false)

      collection = Maintenance::BackfillUserPublicEmailTask.collection
      Maintenance::BackfillUserPublicEmailTask.process(collection)

      refute_predicate user_with_hidden_email.reload, :public_email
      assert_predicate user_with_public_email.reload, :public_email
    end
  end
end
