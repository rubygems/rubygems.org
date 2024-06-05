require "test_helper"

class Admin::AvoPoliciesTest < AdminPolicyTestCase
  def test_association_methods_defined
    resources = Avo::App.init_resources
    association_actions = %w[create attach detach destroy edit show view]

    aggregate_assertions do
      resources.each do |resource|
        policy =
          if resource.authorization_policy
            resource.authorization_policy.new(nil, resource)
          else
            policy!(nil, resource)
          end

        refute_nil policy

        aggregate_assertions policy.class.name do
          resource.fields.each do |field|
            aggregate_assertions field.id do
              case field
              when Avo::Fields::HasBaseField

                association_actions.each do |action|
                  assert_respond_to policy, :"#{action}_#{field.id}?"
                end
              end
            end
          end
        end
      end
    end
  end
end
