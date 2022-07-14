class ProfilesController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?, except: :show
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, except: :show
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, except: :show
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
        Delayed::Job.enqueue EmailResetMailer.new(current_user.id)
        flash[:notice] = t(".confirmation_mail_sent")
      else
        flash[:notice] = t(".updated")
      end
      redirect_to edit_profile_path
    else
      current_user.reload
      render :edit
    end
  end

  def delete
    @only_owner_gems = current_user.only_owner_gems
    @multi_owner_gems = current_user.rubygems_downloaded - @only_owner_gems
  end

  def destroy
    Delayed::Job.enqueue DeleteUser.new(current_user), priority: PRIORITIES[:profile_deletion]
    sign_out
    redirect_to root_path, notice: t(".request_queued")
  end

  def adoptions
    @ownership_calls = current_user.ownership_calls.includes(:user, rubygem: %i[latest_version gem_download])
    @ownership_requests = current_user.ownership_requests.includes(:rubygem)
  end

  private

  def params_user
    params.require(:user).permit(:handle, :twitter_username, :unconfirmed_email, :hide_email).tap do |hash|
      hash.delete(:unconfirmed_email) if hash[:unconfirmed_email] == current_user.email
    end
  end

  def verify_password
    return if current_user.authenticated?(params[:user].delete(:password))
    flash[:notice] = t("profiles.request_denied")
    redirect_to edit_profile_path
  end
end
