# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :redirect_to_root, if: :signed_in?
  before_action :reject_disabled_signup, only: :create

  def new
    @user = User.new
    flash.now[:alert] = t(".registration_disabled") unless signup_enabled?
  end

  def create
    @user = User.new(user_params)
    @user.policies_acknowledged_at = Time.zone.now
    if @user.save
      Mailer.email_confirmation(@user).deliver_later
      flash[:notice] = t(".email_sent")
      redirect_back_or_to root_path
    else
      render template: "users/new"
    end
  end

  private

  def signup_enabled?
    Clearance.configuration.allow_sign_up?
  end
  helper_method :signup_enabled?

  def reject_disabled_signup
    return if signup_enabled?
    @user = User.new
    flash.now[:alert] = t("users.new.registration_disabled")
    render template: "users/new", status: :forbidden
  end

  PERMITTED_USER_PARAMS = %i[
    bio
    email
    handle
    public_email
    location
    password
    website
    twitter_username
    full_name
  ].freeze

  def user_params
    params.expect(user: PERMITTED_USER_PARAMS)
  end
end
