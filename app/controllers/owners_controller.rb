class OwnersController < ApplicationController
  before_action :find_rubygem, except: :gems

  def confirm
    ownership = Ownership.includes(:rubygem).find_by(token: params[:token])

    if ownership&.valid_confirmation_token? && ownership&.confirm_ownership! && ownership&.notify_ownership_change("added")
      sign_in ownership.user
      redirect_to root_path, notice: t(".confirm.confirmed_email", gem: ownership.rubygem.name)
    else
      redirect_to root_path, alert: t("failure_when_forbidden")
    end
  end

  def index
    @owners = @rubygem.owners
  end

  private


end