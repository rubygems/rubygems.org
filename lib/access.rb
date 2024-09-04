module Access
  MAINTAINER = 50
  OWNER = 70

  DEFAULT_ROLE = "owner".freeze

  ROLES = {
    "maintainer" => MAINTAINER,
    "owner" => OWNER
  }.with_indifferent_access.freeze

  def self.flag_for_role(role)
    ROLES.fetch(role)
  end

  def self.role_for_flag(flag)
    ROLES.key(flag)&.inquiry.tap do |role|
      raise ArgumentError, "Unknown role flag: #{flag}" if role.blank?
    end
  end
end