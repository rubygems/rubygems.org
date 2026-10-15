# frozen_string_literal: true

class Events::UserEvent::OIDCApiKeyRole::AccessPolicyChangedComponentPreview < Lookbook::Preview
  # @param name text
  # @param by_owner toggle
  # @param conditions [Array<String>]
  def default(name: "Push example", by_owner: false, conditions: ["sub string_equals repo:example/repo:ref:refs/heads/main"])
    event = FactoryBot.build(:events_user_event, tag: Events::UserEvent::OIDC_API_KEY_ROLE_ACCESS_POLICY_CHANGED, additional:
    {
      name:,
      by_owner:,
      conditions:
    })
    render Events::UserEvent::OIDCApiKeyRole::AccessPolicyChangedComponent.new(
      event:
    )
  end
end
