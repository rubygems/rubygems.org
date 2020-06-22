class OwnersController < ApplicationController
  before_action :find_rubygem, except: :confirm
  before_action :set_ownership, only: :destroy
  before_action :redirect_to_signin, unless: :owner?, except: %i[confirm resend_confirmation]

  def confirm
    ownership = Ownership.includes(:rubygem).find_by(token: params[:token])

    if ownership&.valid_confirmation_token?
      ownership.confirm_and_notify
      redirect_to rubygem_path(ownership.rubygem), notice: t(".confirm.confirmed_email", gem: ownership.rubygem.name)
    else
      redirect_to root_path, alert: t("token_expired")
    end
  end

  def resend_confirmation
    ownership = @rubygem.ownerships.find_by(user: current_user)
    if ownership&.generate_confirmation_token && ownership&.save
      Mailer.delay.ownership_confirmation(ownership.id)
      redirect_to rubygem_path(ownership.rubygem), notice: "A confirmation mail has been re-sent to #{ownership.user.handle}'s email"
    else
      redirect_to root_path, alert: t("try_again")
    end
  end

  def index
    @ownerships = @rubygem.ownerships.includes(:user, :authorizer)
  end

  def create
    owner = User.find_by_name(params[:owner])
    if owner
      ownership = @rubygem.ownerships.new(user: owner, authorizer: current_user)
      if ownership.save
        Mailer.delay.ownership_confirmation(ownership.id)
        redirect_to rubygem_owners_path(@rubygem), notice: "Owner added successfully. A confirmation mail has been sent to #{owner.handle}'s email"
      else
        redirect_to rubygem_owners_path(@rubygem), alert: ownership.errors.full_messages.to_sentence
      end
    else
      redirect_to rubygem_owners_path(@rubygem), alert: "Owner could not be found."
    end
  end

  def destroy
    if @ownership.destroy_and_notify
      redirect_to rubygem_owners_path(@ownership.rubygem), notice: "Owner #{@ownership.user.name} removed successfully!"
    else
      redirect_to rubygem_owners_path(@ownership.rubygem), alert: "Owner cannot be removed!"
    end
  end

  protected

  def set_ownership
    @ownership = Ownership.find(params[:id] || params[:owners_id])
    render_not_found unless @ownership
  end

  def owner?
    @rubygem.owned_by?(current_user)
  end
end
