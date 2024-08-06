module Access
  AccessDeniedError = Class.new(StandardError)

  MAINTAINER = 50
  OWNER = 70

  ROLES = {
    maintainer: MAINTAINER,
    owner: OWNER
  }.freeze

  def self.label_for_role(role)
    key = ROLES.fetch(role.to_sym, nil)
    return nil if key.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.label_for_role_flag(flag)
    raise ArgumentError, "flag must be an integer" unless flag.is_a?(Integer)
    role = ROLES.key(flag) { nil }
    return nil if role.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.permission_for_role(role)
    raise ArgumentError, "A role must be provided" if role.blank?
    ROLES.fetch(role&.to_sym, nil)
  end

  def self.role_for_permission(permission)
    ROLES.key(permission)
  end

  def self.options
    ROLES.map do |role, permission|
      [label_for_role_flag(permission), role]
    end
  end
end
