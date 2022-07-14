class ApiKeysController < ApplicationController
  include ApiKeyable
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :redirect_to_verify, unless: :password_session_active?

  def index
    @api_key  = session.delete(:api_key)
    @api_keys = current_user.api_keys
    redirect_to new_profile_api_key_path if @api_keys.empty?
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def create
    key = generate_unique_rubygems_key
    build_params = { user: current_user, hashed_key: hashed_key(key), **api_key_params }
    @api_key = ApiKey.new(build_params)

    if @api_key.errors.present?
      flash[:error] = @api_key.errors.full_messages.to_sentence
      @api_key = current_user.api_keys.build(api_key_params.merge(rubygem_id: nil))
      return render :new
    end

    if @api_key.save
      Mailer.delay.api_key_created(@api_key.id)

      session[:api_key] = key
      redirect_to profile_api_keys_path, flash: { notice: t(".success") }
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit
    @api_key = current_user.api_keys.find(params.require(:id))
    return unless @api_key.soft_deleted?

    redirect_to profile_api_keys_path
    flash[:error] = t(".invalid_key")
  end

  def update
    @api_key = current_user.api_keys.find(params.require(:id))
    @api_key.assign_attributes(api_key_params)

    if @api_key.errors.present?
      flash[:error] = @api_key.errors.full_messages.to_sentence
      return render :edit
    end

    if @api_key.save
      redirect_to profile_api_keys_path, flash: { notice: t(".success") }
    else
      flash[:error] = @api_key.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    api_key = current_user.api_keys.find(params.require(:id))

    if api_key.destroy
      flash[:notice] = t(".success", name: api_key.name)
    else
      flash[:error] = api_key.errors.full_messages.to_sentence
    end
    redirect_to profile_api_keys_path
  end

  def reset
    if current_user.api_keys.destroy_all
      flash[:notice] = t(".success")
    else
      flash[:error] = t("try_again")
    end
    redirect_to profile_api_keys_path
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name, *ApiKey::API_SCOPES, :mfa, :rubygem_id)
  end

  def redirect_to_verify
    session[:redirect_uri] = profile_api_keys_path
    redirect_to verify_session_path
  end
end
