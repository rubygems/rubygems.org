module OwnersHelper
  def added_mailer_text(owner, user, rubygem)
    if owner.id == user.id
      I18n.t("mailer.owner_added.body_self", gem: rubygem.name)
    else
      I18n.t("mailer.owner_added.body_others", gem: rubygem.name, owner_handle: owner.handle)
    end
  end

  def removed_mailer_text(owner, user, rubygem)
    if owner.id == user.id
      I18n.t("mailer.owner_removed.body_self", gem: rubygem.name)
    else
      I18n.t("mailer.owner_removed.body_others", gem: rubygem.name, owner_handle: owner.handle)
    end
  end

  def confirmation_status(ownership)
    if ownership.confirmed?
      content_tag(:span, "\u2705 Confirmed", class: "owners__span--success")
    else
      content_tag(:span, "\u274C Pending", class: "owners__span--danger")
    end
  end

  def mfa_status(user)
    if user.mfa_level == "disabled"
      content_tag(:span, "\u274C")
    else
      content_tag(:span, "\u2705")
    end
  end
end
