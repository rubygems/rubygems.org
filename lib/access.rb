module Access
  MAINTAINER = 50
  OWNER = 70

  DEFAULT_ROLE = "owner".freeze

  ROLES = {
    "maintainer" => MAINTAINER,
    "owner" => OWNER
  }.with_indifferent_access.freeze

  def self.roles
    ROLES.keys
  end

  def self.label_for_role(role)
    ROLES.fetch(role)
    I18n.t("access.roles.#{role}")
  end

  def self.label_for_role_flag(flag)
    role = ROLES.key(flag)
    raise ArgumentError, "Unknown role flag: #{flag}" if role.blank?
    I18n.t("access.roles.#{role}")
  end

  def self.flag_for_role(role)
    ROLES.fetch(role)
  end

  def self.role_for_flag(flag)
    ROLES.key(flag)&.inquiry.tap do |role|
      raise ArgumentError, "Unknown role flag: #{flag}" if role.blank?
    end
  end

  def self.options
    ROLES.map do |role, flag|
      [label_for_role_flag(flag), role]
    end
  end
end
