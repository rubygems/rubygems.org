class Advisory < ApplicationRecord
  belongs_to :user
  belongs_to :version

  validates :version, :cve, :title, :url, presence: true
  validates :cve, uniqueness: { scope: :version }

  validates_formatting_of :url, using: :url, message: "does not appear to be a valid URL"
end
