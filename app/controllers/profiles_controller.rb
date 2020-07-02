class ProfilesController < ApplicationController
  include CastleTrack

  before_action :redirect_to_signin, unless: :signed_in?, except: :show
  before_action :verify_password, only: %i[update destroy]
  before_action :set_cache_headers, only: :edit

  def edit
    @user = current_user
  end

  def show
    @user           = User.find_by_slug!(params[:id])
    rubygems        = @user.rubygems_downloaded
    @rubygems       = rubygems.slice!(0, 10)
    @extra_rubygems = rubygems
  end

  def update
    @user = current_user.clone
    if @user.update(params_user)
      if @user.unconfirmed_email
        Mailer.delay.email_reset(current_user)
        flash[:notice] = t(".confirmation_mail_sent")
      else
        flash[:notice] = t(".updated")
        track_castle_event(Castle::ProfileUpdateSucceeded, @user)
      end
      redirect_to edit_profile_path
    else
      current_user.reload
      track_castle_event(Castle::ProfileUpdateFailed, current_user)
      render :edit
    end
  end

  def delete
    @only_owner_gems = current_user.only_owner_gems
    @multi_owner_gems = current_user.rubygems_downloaded - @only_owner_gems
  end

  def destroy
    track_castle_event(Castle::ProfileUpdateSucceeded, current_user)
    Delayed::Job.enqueue DeleteUser.new(current_user), priority: PRIORITIES[:profile_deletion]
    sign_out
    redirect_to root_path, notice: t(".request_queued")
  end

  private

  def params_user
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end

  def verify_password
    return if current_user.authenticated?(params[:user].delete(:password))
    flash[:notice] = t("profiles.request_denied")
    track_castle_event(Castle::ProfileUpdateFailed, current_user)
    redirect_to edit_profile_path
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
