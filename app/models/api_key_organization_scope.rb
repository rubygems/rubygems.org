# frozen_string_literal: true

class ApiKeyOrganizationScope < ApplicationRecord
  belongs_to :api_key
  belongs_to :membership

  validates :membership_id, uniqueness: { scope: :api_key_id }

  delegate :organization, to: :membership
end
