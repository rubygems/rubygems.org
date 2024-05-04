class ApiKeysController < ApplicationController
  include ApiKeyable

  include SessionVerifiable
  verify_session_before

  def index
    @api_key  = session.delete(:api_key)
    @api_keys = current_user.api_keys.unexpired.not_oidc.preload(ownership: :rubygem)
    redirect_to new_profile_api_key_path if @api_keys.empty?
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def edit
    @api_key = current_user.api_keys.find(params.permit(:id).require(:id))
    return unless @api_key.soft_deleted?

    flash[:error] = t(".invalid_key")
    redirect_to profile_api_keys_path
  end

  def create
    key = generate_unique_rubygems_key
    build_params = { owner: current_user, hashed_key: hashed_key(key), **api_key_params }
    @api_key = ApiKey.new(build_params)

    if @api_key.errors.present?
      flash.now[:error] = @api_key.errors.full_messages.to_sentence
      @api_key = current_user.api_keys.build(api_key_params.merge(rubygem_id: nil))
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
    @api_key = current_user.api_keys.find(params.permit(:id).require(:id))
    @api_key.assign_attributes(api_key_params(@api_key))

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
    api_key = current_user.api_keys.find(params.permit(:id).require(:id))

    if api_key.expire!
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
      edit_profile_api_key_path(params.permit(:id).require(:id))
    else
      super
    end
  end

  def api_key_params(existing_api_key = nil)
    ApiKeysHelper.api_key_params(params.permit(api_key: PERMITTED_API_KEY_PARAMS).require(:api_key), existing_api_key)
  end

  PERMITTED_API_KEY_PARAMS = [:name, *ApiKey::API_SCOPES, :mfa, :rubygem_id, { scopes: [ApiKey::API_SCOPES] }].freeze
end
