class AuthenticatedUser < User
  def payload
    attrs = {
      "id" => id,
      "handle" => handle,
      "mfa" => mfa_level
    }
    attrs["email"] = email unless hide_email
    attrs
  end
end
