# frozen_string_literal: true

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

  def rubygems_with_history_for(current_rubygems, prior_rubygems)
    current_pairs = current_rubygems.map { |rubygem| [rubygem, nil] }
    prior_pairs = prior_rubygems.map { |ownership| [ownership.rubygem, ownership.removed_at] }

    (current_pairs + prior_pairs).sort_by { |rubygem, _removed_at| -rubygem.downloads }
  end

  def prior_rubygems_of(user)
    current_rubygem_ids = user.ownerships.pluck(:rubygem_id)

    user.historical_ownerships
      .where.not(rubygem_id: current_rubygem_ids)
      .joins(:rubygem).merge(Rubygem.with_versions)
      .preload(rubygem: %i[latest_version most_recent_version gem_download])
      .order(removed_at: :desc)
      .uniq(&:rubygem_id)
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
    return "*" * str.length if str.length <= visible_chars

    visible = str[0, visible_chars]
    hidden_length = str.length - visible_chars
    "#{visible}#{'*' * hidden_length}"
  end
end
