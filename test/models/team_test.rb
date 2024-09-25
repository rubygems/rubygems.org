require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    @team = create(:team, organization: @organization)
  end

  context "validations" do
    should "validate the presence of name and slug" do
      team = build(:team, organization: @organization, name: nil, slug: nil)

      assert_not team.valid?
      assert_includes team.errors.messages[:name], "can't be blank"
      assert_includes team.errors.messages[:slug], "can't be blank"
    end

    should "validate a unique slug within an organization" do
      team = build(:team, organization: @organization, slug: @team.slug)

      assert_not team.valid?
      assert_includes team.errors.messages[:slug], "has already been taken"
    end
  end
end
