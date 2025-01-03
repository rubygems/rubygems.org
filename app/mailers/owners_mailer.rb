class OwnersMailer < ApplicationMailer
  include OwnersHelper
  helper :owners

  def ownership_confirmation(ownership)
    @ownership = ownership
    @user = @ownership.user
    @rubygem = @ownership.rubygem
    mail to: @user.email,
      subject: t("mailer.ownership_confirmation.subject", gem: @rubygem.name, host: Gemcutter::HOST_DISPLAY) do |format|
        format.html
        format.text
      end
  end

  def owner_updated
    @ownership = params[:ownership]
    @user = @ownership.user
    @rubygem = @ownership.rubygem

    mail(
      to: @user.email,
      subject: t("mailer.owner_updated.subject", gem: @rubygem.name, host: Gemcutter::HOST_DISPLAY)
    )
  end

  def owner_removed(user_id, remover_id, gem_id)
    @user = User.find(user_id)
    @remover = User.find(remover_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: t("mailer.owner_removed.subject", gem: @rubygem.name)
  end

  def owner_added(user_id, owner_id, authorizer_id, gem_id)
    @user = User.find(user_id)
    @owner = User.find(owner_id)
    @authorizer = User.find(authorizer_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: t("mailer.owner_added.subject_#{owner_i18n_key(@owner, @user)}", gem: @rubygem.name, owner_handle: @owner.display_handle)
  end
end
