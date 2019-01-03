# frozen_string_literal: true

class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }

  def safe_destroy
    rubygem.owners.many? && destroy
  end
end
