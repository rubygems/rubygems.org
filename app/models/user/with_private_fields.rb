# This enables us to return private fields, like mfa_level, to an authenticated user
# so that they may retrieve this information about their own profile without it
# being exposed to all users in their public profile
class User::WithPrivateFields < User
  def payload
    super.merge({ "mfa" => mfa_level })
  end
end
