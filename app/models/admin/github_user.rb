class Admin::GitHubUser < ApplicationRecord
  # serialize :info_data, Hash

  scope :admins, -> { where(is_admin: true) }

  # for avo
  alias_attribute :name, :login
  alias_attribute :avatar, :avatar_url

  validate :valid_if_admin
  validates :login, presence: true
  validates :github_id, presence: true, uniqueness: true
  validates :info_data, presence: true

  def teams
    info_data.dig(:viewer, :organization, :teams, :edges)&.map { _1[:node] } || []
  end

  def team_member?(slug)
    teams.any? { |team| team[:slug] == slug }
  end

  def valid_if_admin
    return unless is_admin

    errors.add(:is_admin, "missing oauth token") if oauth_token.blank?
    errors.add(:is_admin, "missing info data") if info_data.blank?
    errors.add(:is_admin, "missing viewer login") if info_data.dig(:viewer, :login).blank?
    errors.add(:is_admin, "missing rubygems org") if info_data.dig(:viewer, :organization, :login) != "rubygems"
    errors.add(:is_admin, "not a member of the rubygems org") unless info_data.dig(:viewer, :organization, :viewerIsAMember)
  end

  def info_data=(info_data)
    info_data = info_data&.deep_symbolize_keys || {}
    super
    self.login = info_data.dig(:viewer, :login)
    self.github_id = info_data.dig(:viewer, :id)
    self.avatar_url = info_data.dig(:viewer, :avatarUrl)
  end

  def info_data
    super&.deep_symbolize_keys
  end
end
