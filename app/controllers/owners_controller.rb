class OwnersController < ApplicationController
  include SessionVerifiable

  before_action :find_rubygem, except: :confirm
  verify_session_before only: %i[index edit update create destroy]
  before_action :verify_mfa_requirement, only: %i[create edit update destroy]
  before_action :find_ownership, only: %i[edit update destroy]

  rescue_from(Pundit::NotAuthorizedError) do |e|
    redirect_to rubygem_path(@rubygem.slug), alert: e.policy.error
  end

  def confirm
    ownership = Ownership.find_by!(token: token_params)

    if ownership.valid_confirmation_token? && ownership.confirm!
      notify_owner_added(ownership)
      redirect_to rubygem_path(ownership.rubygem.slug), notice: t(".confirmed_email", gem: ownership.rubygem.name)
    else
      redirect_to root_path, alert: t(".token_expired")
    end
  end

  def resend_confirmation
    ownership = @rubygem.unconfirmed_ownerships.find_by!(user: current_user)
    if ownership.generate_confirmation_token && ownership.save
      OwnersMailer.ownership_confirmation(ownership).deliver_later
      flash[:notice] = t(".resent_notice")
    else
      flash[:alert] = t("try_again")
    end
    redirect_to rubygem_path(ownership.rubygem.slug)
  end

  def index
    authorize @rubygem, :show_unconfirmed_ownerships?
    @ownerships = @rubygem.ownerships_including_unconfirmed.includes(:user, :authorizer)
  end

  def edit
  end

  def create
    authorize @rubygem, :add_owner?
    owner = User.find_by_name(handle_params)

    ownership = @rubygem.ownerships.new(user: owner, authorizer: current_user, role: params[:role])
    if ownership.save
      OwnersMailer.ownership_confirmation(ownership).deliver_later
      redirect_to rubygem_owners_path(@rubygem.slug), notice: t(".success_notice", handle: owner.name)
    else
      index_with_error ownership.errors.full_messages.to_sentence, :unprocessable_entity
    end
  end

  # This action is used to update a user's owenrship role. This endpoint currently asssumes
  # the role is the only thing that can be updated. If more fields are added to the ownership
  # this action will need to be tweaked a bit
  def update
    if @ownership.update(update_params)
      OwnersMailer.with(ownership: @ownership, authorizer: current_user).owner_updated.deliver_later
      redirect_to rubygem_owners_path(@ownership.rubygem.slug), notice: t(".success_notice", handle: @ownership.user.name)
    else
      index_with_error @ownership.errors.full_messages.to_sentence, :unprocessable_entity
    end
  end

  def destroy
    if @ownership.safe_destroy
      OwnersMailer.owner_removed(@ownership.user_id, current_user.id, @ownership.rubygem_id).deliver_later
      redirect_to rubygem_owners_path(@ownership.rubygem.slug), notice: t(".removed_notice", owner_name: @ownership.owner_name)
    else
      index_with_error t(".failed_notice"), :forbidden
    end
  end

  private

  def verify_session_redirect_path
    rubygem_owners_url(params[:rubygem_id])
  end

  def find_ownership
    @ownership = @rubygem.ownerships_including_unconfirmed.find_by_owner_handle(handle_params)
    return authorize(@ownership) if @ownership

    predicate = params[:action] == "destroy" ? :remove_owner? : :update_owner?
    authorize(@rubygem, predicate)
    render_not_found
  end

  def token_params
    params.permit(:token).require(:token)
  end

  def handle_params
    params.permit(:handle).require(:handle)
  end

  def update_params
    params.permit(:role)
  end

  def notify_owner_added(ownership)
    ownership.rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.owner_added(
        notified_user.id,
        ownership.user_id,
        ownership.authorizer.id,
        ownership.rubygem_id
      ).deliver_later
    end
  end

  def index_with_error(msg, status)
    @ownerships = @rubygem.ownerships_including_unconfirmed.includes(:user, :authorizer)
    flash.now[:alert] = msg
    render :index, status: status
  end

  def verify_mfa_requirement
    return if @rubygem.mfa_requirement_satisfied_for?(current_user)
    index_with_error t("owners.mfa_required"), :forbidden
  end
end
