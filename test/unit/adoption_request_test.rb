require 'test_helper'

class AdoptionRequestTest < ActiveSupport::TestCase
  subject { create(:adoption_request) }

  should belong_to :user
  should belong_to :rubygem
  should validate_presence_of(:rubygem)
  should validate_presence_of(:user)

  context "validation" do
    should "not allow unspecified status" do
      assert_raises(ArgumentError) { build(:adoption_request, status: "unknown") }

      adoption_request = build(:adoption_request, status: "opened")
      assert adoption_request.valid?
      assert_nil adoption_request.errors[:handle].first
    end
  end
end
