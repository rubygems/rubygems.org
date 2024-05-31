class ProfilesController < ApplicationController
  include EmailResettable

  before_action :redirect_to_signin, unless: :signed_in?, except: :show
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, except: :show
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, except: :show
  before_action :verify_password, only: %i[update destroy]
  before_action :disable_cache, only: :edit

  def show
    @user = User.find_by_slug!(params[:id])
    @rubygems = @user.rubygems_downloaded.includes(%i[latest_version gem_download]).strict_loading
  end

  def me
    redirect_to profile_path(current_user.display_id)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user.clone
    if @user.update(params_user)
      if @user.unconfirmed_email
        email_reset(current_user)
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
    @multi_owner_gems = current_user.rubygems_downloaded.to_a - @only_owner_gems
  end

  def destroy
    DeleteUserJob.perform_later(user: current_user)
    sign_out
    redirect_to root_path, notice: t(".request_queued")
  end

  def adoptions
    @ownership_calls = current_user.ownership_calls.includes(:user, rubygem: %i[latest_version gem_download])
    @ownership_requests = current_user.ownership_requests.includes(:rubygem)
  end

  def security_events
    @security_events = current_user.events.order(id: :desc).page(params[:page]).per(50)
    render Profiles::SecurityEventsView.new(security_events: @security_events)
  end

  private

  def params_user
    params.permit(user: PERMITTED_PROFILE_PARAMS).require(:user).tap do |hash|
      hash.delete(:unconfirmed_email) if hash[:unconfirmed_email] == current_user.email
    end
  end

  PERMITTED_PROFILE_PARAMS = %i[handle twitter_username unconfirmed_email public_email full_name].freeze

  def verify_password
    password = params.permit(user: :password).require(:user)[:password]
    return if current_user.authenticated?(password)
    redirect_to edit_profile_path, notice: t("profiles.request_denied")
  end
end
