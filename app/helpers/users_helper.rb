module UsersHelper
  def twitter_username(user)
    "@#{user.twitter_username}" if user.twitter_username.present?
  end

  def twitter_url(user)
    "https://twitter.com/#{user.twitter_username}"
  end

  def show_policies_acknowledge_banner?(user)
    user.present? && !user.policies_acknowledged?
  end

  def obfuscate_email(email)
    return email if email.blank?

    local, domain = email.split("@", 2)
    return email unless domain

    domain_name, tld = domain.split(".", 2)
    return email unless tld

    obfuscated_local = obfuscate_part(local, 1)
    obfuscated_domain = obfuscate_part(domain_name, 1)

    "#{obfuscated_local}@#{obfuscated_domain}.#{tld}"
  end

  private

  def obfuscate_part(str, visible_chars)
    return str if str.length <= visible_chars + 1

    visible = str[0, visible_chars]
    hidden_length = str.length - visible_chars
    "#{visible}#{'*' * hidden_length}"
  end
end
