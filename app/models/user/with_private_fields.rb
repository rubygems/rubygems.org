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
      "[WARNING] For protection of your account and gems, we encourage you to set up multi-factor authentication " \
        "at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future."
    elsif mfa_recommended_weak_level_enabled?
      "[WARNING] For protection of your account and gems, we encourage you to change your multi-factor authentication " \
        "level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit. " \
        "Your account will be required to have MFA enabled on one of these levels in the future."
    end
  end
end
