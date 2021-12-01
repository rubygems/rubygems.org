class OwnersController < ApplicationController
  before_action :find_rubygem, except: :confirm
  before_action :render_forbidden, unless: :owner?, except: %i[confirm resend_confirmation]
  before_action :redirect_to_verify, unless: :password_session_active?, only: %i[index create destroy]
  before_action :verify_mfa_requirement, only: %i[create destroy]

  def confirm
    ownership = Ownership.find_by!(token: token_params)

    if ownership.valid_confirmation_token? && ownership.confirm!
      notify_owner_added(ownership)
      redirect_to rubygem_path(ownership.rubygem), notice: t(".confirmed_email", gem: ownership.rubygem.name)
    else
      redirect_to root_path, alert: t(".token_expired")
    end
  end

  def resend_confirmation
    ownership = @rubygem.unconfirmed_ownerships.find_by!(user: current_user)
    if ownership.generate_confirmation_token && ownership.save
      Delayed::Job.enqueue(OwnershipConfirmationMailer.new(ownership.id))
      flash[:notice] = t(".resent_notice")
    else
      flash[:alert] = t("try_again")
    end
    redirect_to rubygem_path(ownership.rubygem)
  end

  def index
    @ownerships = @rubygem.ownerships_including_unconfirmed.includes(:user, :authorizer)
  end

  def create
    owner = User.find_by_name(handle_params)
    ownership = @rubygem.ownerships.new(user: owner, authorizer: current_user)
    if ownership.save
      Delayed::Job.enqueue(OwnershipConfirmationMailer.new(ownership.id))
      redirect_to rubygem_owners_path(@rubygem), notice: t(".success_notice", handle: owner.name)
    else
      index_with_error ownership.errors.full_messages.to_sentence, :unprocessable_entity
    end
  end

  def destroy
    @ownership = @rubygem.ownerships_including_unconfirmed.find_by_owner_handle!(handle_params)
    if @ownership.safe_destroy
      OwnersMailer.delay.owner_removed(@ownership.user_id, current_user.id, @ownership.rubygem_id)
      redirect_to rubygem_owners_path(@ownership.rubygem), notice: t(".removed_notice", owner_name: @ownership.owner_name)
    else
      index_with_error t(".failed_notice"), :forbidden
    end
  end

  private

  def redirect_to_verify
    session[:redirect_uri] = rubygem_owners_url(@rubygem)
    redirect_to verify_session_path
  end

  def token_params
    params.require(:token)
  end

  def handle_params
    params.require(:handle)
  end

  def notify_owner_added(ownership)
    ownership.rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.delay.owner_added(notified_user.id,
        ownership.user_id,
        ownership.authorizer.id,
        ownership.rubygem_id)
    end
  end

  def index_with_error(msg, status)
    @ownerships = @rubygem.ownerships_including_unconfirmed.includes(:user, :authorizer)
    flash[:alert] = msg
    render :index, status: status
  end

  def verify_mfa_requirement
    return if @rubygem.mfa_requirement_satisfied_for?(current_user)
    index_with_error t("owners.mfa_required"), :forbidden
  end
end
