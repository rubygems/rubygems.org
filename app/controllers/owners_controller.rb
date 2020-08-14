class OwnersController < ApplicationController
  before_action :find_rubygem, except: :confirm
  before_action :redirect_to_signin, unless: :owner?, except: %i[confirm resend_confirmation]
  before_action :redirect_to_verify, unless: :password_session_active?, only: %i[index create destroy]

  def confirm
    ownership = Ownership.includes(:rubygem).find_by!(token: params[:token])

    if ownership.valid_confirmation_token?
      ownership.confirm_and_notify
      redirect_to rubygem_path(ownership.rubygem), notice: t(".confirm.confirmed_email", gem: ownership.rubygem.name)
    else
      redirect_to root_path, alert: t(".confirm.token_expired")
    end
  end

  def resend_confirmation
    ownership = @rubygem.ownerships_including_unconfirmed.find_by!(user: current_user)
    if ownership.generate_confirmation_token && ownership.save
      OwnersMailer.delay.ownership_confirmation(ownership.id)
      flash[:notice] = t("owners.resend_confirmation.resent_notice", handle: ownership.owner_name)
    else
      flash[:alert] = t("try_again")
    end
    redirect_to rubygem_path(ownership.rubygem)
  end

  def index
    @ownerships = @rubygem.ownerships_including_unconfirmed.includes(:user, :authorizer)
  end

  def create
    owner = User.find_by_name(params[:handle])
    ownership = @rubygem.ownerships.new(user: owner, authorizer: current_user)
    if ownership.save
      OwnersMailer.delay.ownership_confirmation(ownership.id)
      redirect_to rubygem_owners_path(@rubygem), notice: t("owners.create.success_notice", handle: owner.name)
    else
      redirect_to rubygem_owners_path(@rubygem), alert: ownership.errors.full_messages.to_sentence
    end
  end

  def destroy
    @ownership = @rubygem.ownerships_including_unconfirmed.find_by_owner_handle!(params[:handle])
    if @ownership.destroy_and_notify(current_user)
      redirect_to rubygem_owners_path(@ownership.rubygem), notice: t("owners.destroy.removed_notice", owner_name: @ownership.owner_name)
    else
      redirect_to rubygem_owners_path(@ownership.rubygem), alert: t("owners.destroy.failed_notice")
    end
  end

  protected

  def owner?
    @rubygem.owned_by?(current_user)
  end

  def password_session_active?
    session[:verification] && session[:verification] > Time.current
  end

  def redirect_to_verify
    session[:redirect_uri] = rubygem_owners_url(@rubygem)
    redirect_to user_password_path(current_user)
  end
end
