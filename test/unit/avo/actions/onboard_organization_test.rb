require "test_helper"

class OnboardOrganizationTest < ActiveSupport::TestCase
  setup do
    @onboarding = create(:organization_onboarding)
    @current_user = create(:admin_github_user, :is_admin)
    @resource = Avo::Resources::OrganizationOnboarding.new.hydrate(record: @onboarding)
    @action = Avo::Actions::OnboardOrganization.new(resource: @resource, user: @current_user, view: :edit)
  end

  should "onboard an organization" do
    args = {
      current_user: @current_user,
      resource: @resource,
      fields: {
        comment: "Onboarding a new organization 1234567"
      },
      query: [@onboarding]
    }

    @action.handle(**args)

    assert_predicate @onboarding.reload, :completed?
  end

  # Avo does not have an easy and direct way to test the message & visible class attributes.
  # calling the lambda directly will raise an error because Avo requires the entire app to be loaded.

  should "ask for confirmation" do
    action_mock = Data.define(:record).new(record: @onboarding)

    assert_not_nil action_mock.instance_exec(&Avo::Actions::OnboardOrganization.message)
  end

  should "be visible" do
    action_mock = Data.define(:current_user, :view, :record).new(current_user: @current_user, view: :show, record: @onboarding)

    assert action_mock.instance_exec(&Avo::Actions::OnboardOrganization.visible)
  end
end
