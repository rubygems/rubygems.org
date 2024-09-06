module Access
  AccessDeniedError = Class.new(StandardError)

  MAINTAINER = 50
  OWNER = 70

  ROLES = {
    maintainer: MAINTAINER,
    owner: OWNER
  }

  def self.label_for_role(role)
    key = ROLES.fetch(role.to_sym) { nil }
    return nil if key.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.label_for_role_flag(flag)
    raise ArgumentError, "flag must be an integer" unless flag.is_a?(Integer)
    role = ROLES.key(flag) { nil }
    return nil if role.nil?
    I18n.t("access.roles.#{role}")
  end

  def self.options
    ROLES.map do |_, permission|
      [label_for_role_flag(permission), permission]
    end
  end
end
