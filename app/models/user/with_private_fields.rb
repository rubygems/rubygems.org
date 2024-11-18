# This enables us to return private fields, like mfa_level, to an authenticated user
# so that they may retrieve this information about their own profile without it
# being exposed to all users in their public profile
class User::WithPrivateFields < User
  def payload
    super.merge({ "mfa" => mfa_level, "warning" => mfa_warning })
  end

  private

  def mfa_warning
    if mfa_recommended_not_yet_enabled?
      I18n.t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp
    elsif mfa_recommended_weak_level_enabled?
      I18n.t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp
    end
  end
end
