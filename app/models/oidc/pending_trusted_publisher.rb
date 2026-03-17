# frozen_string_literal: true

class OIDC::PendingTrustedPublisher < ApplicationRecord
  belongs_to :user
  belongs_to :trusted_publisher, polymorphic: true, optional: false

  accepts_nested_attributes_for :trusted_publisher

  validates :rubygem_name,
    length: { maximum: Gemcutter::MAX_FIELD_LENGTH },
    presence: true,
    name_format: true,
    uniqueness: { case_sensitive: false, scope: %i[trusted_publisher_id trusted_publisher_type], conditions: -> { unexpired } }

  validate :available_rubygem_name, on: :create
  validate :protected_gem_typo, on: :create

  scope :unexpired, -> { where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].gt(Time.now.utc))) }
  scope :expired, -> { where(arel_table[:expires_at].lteq(Time.now.utc)) }

  scope :rubygem_name_is, lambda { |name|
    sensitive = where(rubygem_name: name.strip).limit(1)
    return sensitive unless sensitive.empty?

    where("UPPER(rubygem_name) = UPPER(?)", name.strip).limit(1)
  }

  def build_trusted_publisher(params)
    self.trusted_publisher = trusted_publisher_type.constantize.build_trusted_publisher(params)
  end

  private

  def available_rubygem_name
    return if rubygem_name.blank?
    rubygem = Rubygem.name_is(rubygem_name).first
    return if rubygem.nil? || rubygem.pushable?

    errors.add(:rubygem_name, :unavailable)
  end

  def protected_gem_typo
    return if rubygem_name.blank?
    gem_typo = GemTypo.new(rubygem_name)

    return unless gem_typo.protected_typo?
    errors.add :rubygem_name, "'#{rubygem_name}' is too similar to an existing gem named '#{gem_typo.protected_gem}'"
  end
end
