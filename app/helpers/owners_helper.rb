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

  def owner_added_subject(owner, user, rubygem)
    if owner.id == user.id
      I18n.t("mailer.owner_added.subject_self", gem: rubygem.name)
    else
      I18n.t("mailer.owner_added.subject_others", gem: rubygem.name, owner_handle: owner.handle)
    end
  end

  def owner_removed_subject(owner, user, rubygem)
    if owner.id == user.id
      I18n.t("mailer.owner_removed.subject_self", gem: rubygem.name)
    else
      I18n.t("mailer.owner_removed.subject_others", gem: rubygem.name, owner_handle: owner.handle)
    end
  end

  def confirmation_status(ownership)
    if ownership.confirmed?
      content_tag(:span, class: "owners__icon") do
        concat image_tag("/images/check.svg")
        concat "Confirmed"
      end
    else
      content_tag(:span, class: "owners__icon") do
        concat image_tag("/images/clock.svg")
        concat "Pending"
      end
    end
  end

  def mfa_status(user)
    if user.mfa_level == "disabled"
      content_tag(:span, image_tag("/images/x.svg"), class: "owners__icon")
    else
      content_tag(:span, image_tag("/images/check.svg"), class: "owners__icon")
    end
  end
end
