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
end
