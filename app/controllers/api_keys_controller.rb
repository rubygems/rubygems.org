# frozen_string_literal: true

class ApiKeysController < ApplicationController
  before_action :disable_cache, only: :index
  before_action :set_page, only: :index

  layout "subject", only: %i[index new edit create update]

  include ApiKeyable
  include SessionVerifiable

  verify_session_before

  def index
    @api_key = session.delete(:api_key)
    @expired_view = params[:expired] == "true"
    api_keys = current_user.api_keys.not_oidc
    @has_expired_keys = api_keys.expired.exists?
    scope = @expired_view ? api_keys.expired.order(expires_at: :desc, id: :desc) : api_keys.unexpired
    @api_keys = scope.preload(ownership: :rubygem).page(@page)
    redirect_to new_profile_api_key_path if !@expired_view && @api_keys.empty? && !@has_expired_keys
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def edit
    @api_key = current_user.api_keys.find(params.expect(:id))
    error = if @api_key.soft_deleted?
              t(".invalid_key")
            elsif @api_key.expired?
              t(".expired_key")
            end
    return if error.blank?

    flash[:error] = error
    redirect_to profile_api_keys_path
  end

  def create
    key = generate_unique_rubygems_key
    build_params = { owner: current_user, hashed_key: hashed_key(key), **api_key_create_params }
    @api_key = ApiKey.new(build_params)

    if @api_key.errors.present?
      flash.now[:error] = @api_key.errors.full_messages.to_sentence
      @api_key = current_user.api_keys.build(api_key_create_params.merge(rubygem_id: nil))
      return render :new
    end

    if @api_key.save
      Mailer.api_key_created(@api_key.id).deliver_later

      session[:api_key] = key
      redirect_to profile_api_keys_path, flash: { notice: t(".success") }
    else
      flash.now[:error] = @api_key.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    @api_key = current_user.api_keys.find(params.expect(:id))
    @api_key.assign_attributes(api_key_update_params(@api_key))

    if @api_key.errors.present?
      flash.now[:error] = @api_key.errors.full_messages.to_sentence
      return render :edit
    end

    if @api_key.save
      redirect_to profile_api_keys_path, flash: { notice: t(".success") }
    else
      flash.now[:error] = @api_key.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    api_key = current_user.api_keys.find(params.expect(:id))

    if api_key.expired?
      flash[:error] = t(".already_expired")
    elsif api_key.expire!
      flash[:notice] = t(".success", name: api_key.name)
    else
      flash[:error] = api_key.errors.full_messages.to_sentence
    end
    redirect_to profile_api_keys_path
  end

  def reset
    if current_user.api_keys.expire_all!
      flash[:notice] = t(".success")
    else
      flash[:error] = t("try_again")
    end
    redirect_to profile_api_keys_path
  end

  private

  def verify_session_redirect_path
    case action_name
    when "reset", "destroy"
      profile_api_keys_path
    when "create"
      new_profile_api_key_path
    when "update"
      edit_profile_api_key_path(params[:id])
    else
      super
    end
  end

  def api_key_create_params
    ApiKeysHelper.api_key_params(params.expect(api_key: [:name, *ApiKey::API_SCOPES, :mfa, :rubygem_id, :expires_at]))
  end

  def api_key_update_params(existing_api_key = nil)
    ApiKeysHelper.api_key_params(
      params.expect(api_key: [*ApiKey::API_SCOPES, :mfa, :rubygem_id, scopes: ApiKey::API_SCOPES]), existing_api_key
    )
  end
end
