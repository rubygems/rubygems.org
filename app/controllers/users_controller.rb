class UsersController < Clearance::UsersController
  include CastleTrack

  def new
    redirect_to sign_up_path
  end

  def create
    @user = user_from_params
    if @user.save
      Mailer.delay.email_confirmation(@user)
      flash[:notice] = t(".email_sent")
      track_castle_event(Castle::RegistrationSucceeded, @user)
      redirect_back_or url_after_create
    else
      track_castle_event(Castle::RegistrationFailed, @user)
      render template: "users/new"
    end
  rescue ActionController::ParameterMissing => e
    track_castle_event(Castle::RegistrationFailed, nil)
    render plain: "Request is missing param '#{e.param}'", status: :bad_request
  end

  private

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
