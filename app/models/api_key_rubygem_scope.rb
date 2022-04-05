class ApiKeyRubygemScope < ApplicationRecord
  belongs_to :api_key
  belongs_to :ownership
  validates :ownership_id, uniqueness: { scope: :api_key_id }
  validates :api_key, :ownership, presence: true
  before_destroy :soft_delete_api_key!, if: :destroyed_by_association

  private

  def soft_delete_api_key!
    api_key.soft_delete!
  end
end
