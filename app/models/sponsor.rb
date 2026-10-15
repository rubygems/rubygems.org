# frozen_string_literal: true

class Sponsor < ApplicationRecord
  has_one_attached :logo
  # Retain the audit history (including its Global ID) after deletion.
  has_many :audits, as: :auditable, dependent: nil

  enum :tier, { infrastructure: 0, open_source: 1, supporter_plus: 2 }, validate: true

  validates :name, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :website_url, presence: true, unless: :anonymous?
  validates_formatting_of :website_url, using: :url, allow_blank: true, message: "does not appear to be a valid URL"
  validates :website_url, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :website_url, format: { with: %r{\Ahttps?://} }, allow_blank: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :acceptable_logo

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(anonymous: false) }
  scope :in_footer, -> { visible.where(show_in_footer: true).ordered }

  private

  def acceptable_logo
    unless logo.attached?
      errors.add(:logo, "must be attached for public sponsors") unless anonymous?
      return
    end

    errors.add(:logo, "must be PNG or WebP") unless logo.content_type.in?(%w[image/png image/webp])
    errors.add(:logo, "must be no larger than 256 KB; optimize it before uploading") if logo.byte_size > 256.kilobytes

    # Do not accept signed IDs for existing blobs from another record. Logos
    # must be new multipart uploads, not a way to publish a private attachment.
    return unless attachment_changes["logo"] && logo.blob.persisted?
    errors.add(:logo, "must be a new upload")
  end
end
