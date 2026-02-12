module OwnersHelper
  def owner_i18n_key(owner, user)
    owner.id == user.id ? "self" : "others"
  end

  def confirmation_status(ownership)
    if ownership.confirmed?
      image_tag("/images/check.svg") + t("owners.index.confirmed")
    else
      image_tag("/images/clock.svg") + t("owners.index.pending")
    end
  end

  def mfa_status(user)
    if user.mfa_level == "disabled"
      image_tag("/images/x.svg")
    else
      image_tag("/images/check.svg")
    end
  end

  def can_add_owner?(rubygem)
    policy(rubygem).add_owner?
  end

  def can_modify_owners?(rubygem)
    policy(rubygem).update_owner?
  end

  def can_remove_owners?(rubygem)
    policy(rubygem).remove_owner?
  end

  def can_modify_or_remove_owners?(rubygem)
    can_modify_owners?(rubygem) || can_remove_owners?(rubygem)
  end
end
