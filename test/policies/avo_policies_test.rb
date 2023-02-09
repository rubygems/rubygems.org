require "test_helper"

class AvoPoliciesTest < ActiveSupport::TestCase
  def test_association_methods_defined
    resources = Avo::App.init_resources
    association_actions = %w[create attach detach destroy edit show view]

    resources.each do |resource|
      policy = Pundit.policy(nil, resource)
      refute_nil policy

      resource.fields.each do |field|
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
