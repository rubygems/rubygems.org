# frozen_string_literal: true

class DropOrganizationOnboardingNameType < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column(:organization_onboardings, :name_type, :string)
    end
  end
end
