module Access
  AccessDeniedError = Class.new(StandardError)

  GUEST = 0
  MAINTAINER = 50
  ADMIN = 60
  OWNER = 70

  DEFAULT_ROLE = "owner".freeze

  ROLES = {
    "maintainer" => MAINTAINER,
    "admin" => ADMIN,
    "owner" => OWNER
  }.freeze

  def self.roles
    ROLES.keys
  end

  def self.label_for_role(role)
    key = ROLES.fetch(role.to_s, nil)
    return nil if key.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.label_for_role_flag(flag)
    role = ROLES.key(flag) { nil }
    return nil if role.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.flag_for_role(role)
    ROLES.fetch(role.to_s, nil)
  end

  def self.role_for_flag(flag)
    ROLES.key(flag)&.inquiry
  end

  def self.options
    ROLES.map do |role, flag|
      [label_for_role_flag(flag), role]
    end
  end
end
