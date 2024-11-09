require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    @team = create(:team, organization: @organization)
  end

  context "validations" do
    should "validate the presence of name and handle" do
      team = build(:team, organization: @organization, name: nil, handle: nil)

      assert_not team.valid?
      assert_includes team.errors.messages[:name], "can't be blank"
      assert_includes team.errors.messages[:handle], "can't be blank"
    end

    should "validate a unique handle within an organization" do
      team = build(:team, organization: @organization, handle: @team.handle)

      assert_not team.valid?
      assert_includes team.errors.messages[:handle], "has already been taken"
    end
  end
end
