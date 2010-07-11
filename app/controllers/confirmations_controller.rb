class ConfirmationsController < Clearance::ConfirmationsController
  private

  def redirect_signed_out_confirmed_user
    user = User.find(params[:user_id])
    if user && user.email_confirmed? && !user.email_reset && signed_out?
      flash_already_confirmed
      redirect_to(url_already_confirmed)
    end
  end
end
