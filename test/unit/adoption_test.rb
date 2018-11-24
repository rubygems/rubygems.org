require 'test_helper'

class AdoptionTest < ActiveSupport::TestCase
  subject { create(:adoption) }

  should belong_to :user
  should belong_to :rubygem
  should validate_presence_of(:rubygem)
  should validate_presence_of(:user)

  context "validation" do
    should "not allow unspecified status" do
      assert_raises(ArgumentError) { build(:adoption, status: "unknown") }

      adoption = build(:adoption, status: "requested")
      assert adoption.valid?
      assert_nil adoption.errors[:handle].first
    end
  end
end
