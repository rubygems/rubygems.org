module MailerHelper
  def mfa_required_soon_subject(mfa_level)
    case mfa_level
    when "disabled"
      "[Action Required] Enable multi-factor authentication on your RubyGems account by August 15"
    when "ui_only"
      "[Action Required] Upgrade the multi-factor authentication level on your RubyGems account by August 15"
    end
  end

  def mfa_required_soon_heading(mfa_level)
    case mfa_level
    when "disabled"
      "Enable multi-factor authentication on your RubyGems account"
    when "ui_only"
      "Upgrade the multi-factor authentication level on your RubyGems account"
    end
  end

  def mfa_required_popular_gems_subject(mfa_level)
    case mfa_level
    when "disabled"
      "[Action Required] Enabling multi-factor authentication is required on your RubyGems account"
    when "ui_only"
      "[Action Required] Upgrading the multi-factor authentication level is required on your RubyGems account"
    end
  end

  def mfa_required_popular_gems_heading(mfa_level)
    case mfa_level
    when "disabled"
      "Enable multi-factor authentication on your RubyGems account"
    when "ui_only"
      "Upgrade the multi-factor authentication level on your RubyGems account"
    end
  end
end
