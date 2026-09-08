# frozen_string_literal: true

class OIDC::ApiKeyPermissions < ApplicationModel
  def create_params(user)
    params = { scopes: scopes }
    params[:ownership] = gems&.first&.then { user.ownerships.joins(:rubygem).find_by!(rubygem: { name: it }) }
    if organization.present?
      org = Organization.find_by_handle!(organization)
      params[:membership] = user.memberships.confirmed.with_minimum_role(:admin).find_by!(organization_id: org.id)
    end
    params[:expires_at] = DateTime.now.utc + valid_for
    params
  end

  attribute :scopes, Types::ArrayOf.new(:string)
  attribute :valid_for, :duration, default: -> { 30.minutes.freeze }
  attribute :gems, Types::ArrayOf.new(:string)
  attribute :organization, :string

  validates :scopes, presence: true
  validate :known_scopes?
  validate :scopes_must_be_unique
  validate :exclusive_gems_and_organization

  validates :valid_for, presence: true, inclusion: { in: (5.minutes)..(1.day) }

  validates :gems, length: { maximum: 1 }

  def gems=(gems)
    if gems == [""] # all gems, from form
      super(nil)
    else
      super
    end
  end

  def organization=(value)
    super(value.presence)
  end

  def known_scopes?
    scopes&.each_with_index do |scope, idx|
      errors.add("scopes[#{idx}]", "unknown scope: #{scope}") unless ApiKey::API_SCOPES.include?(scope.to_sym)
    end
  end

  def scopes_must_be_unique
    return if scopes.blank?

    errors.add(:scopes, "show_dashboard is exclusive") if scopes.include?("show_dashboard") && scopes.size > 1
    errors.add(:scopes, "must be unique") if scopes.dup.uniq!
  end

  def exclusive_gems_and_organization
    return if gems.blank? || organization.blank?

    errors.add(:base, "cannot be scoped to both a gem and an organization")
  end
end
