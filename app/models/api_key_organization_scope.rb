# frozen_string_literal: true

class ApiKeyOrganizationScope < ApplicationRecord
  belongs_to :api_key
  belongs_to :membership

  validates :membership_id, uniqueness: { scope: :api_key_id }
  before_destroy :soft_delete_api_key!, if: :destroyed_by_association

  delegate :organization, to: :membership

  private

  def soft_delete_api_key!
    api_key.soft_delete!(membership: membership)
  end
end
