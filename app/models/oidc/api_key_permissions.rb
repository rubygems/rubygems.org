class OIDC::ApiKeyPermissions < ApplicationModel
  def create_params(user)
    params = scopes.map(&:to_sym).index_with(true)
    params[:ownership] = gems&.first&.then { user.ownerships.joins(:rubygem).find_by!(rubygem: { name: _1 }) }
    params[:expires_at] = DateTime.now.utc + valid_for
    params
  end

  attribute :scopes, Types::ArrayOf.new(:string)
  attribute :valid_for, :duration, default: -> { 30.minutes.freeze }
  attribute :gems, Types::ArrayOf.new(:string)

  validates :scopes, presence: true
  validate :known_scopes?
  validate :scopes_must_be_unique

  validates :valid_for, presence: true, inclusion: { in: (5.minutes)..(1.day) }

  validates :gems, length: { maximum: 1 }

  def gems=(gems)
    if gems == [""] # all gems, from form
      super(nil)
    else
      super
    end
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
end
