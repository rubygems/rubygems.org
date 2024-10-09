class Api::V1::OwnersController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show gems]
  before_action :verify_with_otp, except: %i[show gems]
  before_action :find_rubygem, except: :gems

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def show
    respond_to do |format|
      format.json { render json: @rubygem.owners }
      format.yaml { render yaml: @rubygem.owners }
    end
  end

  def create
    authorize @rubygem, :add_owner?
    owner = User.find_by_name!(email_param)
    ownership = @rubygem.ownerships.new(user: owner, authorizer: @api_key.user, **ownership_params)

    if ownership.save
      OwnersMailer.ownership_confirmation(ownership).deliver_later
      render plain: response_with_mfa_warning("#{owner.display_handle} was added as an unconfirmed owner. " \
                                              "Ownership access will be enabled after the user clicks on the " \
                                              "confirmation mail sent to their email.")
    else
      render plain: response_with_mfa_warning(ownership.errors.full_messages.to_sentence), status: :unprocessable_entity
    end
  end

  def update
    owner = User.find_by_name(email_param)
    ownership = @rubygem.ownerships.find_by(user: owner) if owner
    if ownership
      authorize(ownership)
    else
      authorize(@rubygem, :update_owner?) # don't leak presence of an email unless authorized
      return render_not_found
    end

    if ownership.update(ownership_params)
      render plain: response_with_mfa_warning("Owner updated successfully.")
    else
      render plain: response_with_mfa_warning(ownership.errors.full_messages.to_sentence), status: :unprocessable_entity
    end
  end

  def destroy
    authorize @rubygem, :remove_owner?
    owner = User.find_by_name!(email_param)
    ownership = @rubygem.ownerships_including_unconfirmed.find_by!(user: owner)

    if ownership.safe_destroy
      OwnersMailer.owner_removed(ownership.user_id, @api_key.user.id, ownership.rubygem_id).deliver_later
      render plain: response_with_mfa_warning("Owner removed successfully.")
    else
      render plain: response_with_mfa_warning("Unable to remove owner."), status: :forbidden
    end
  end

  def gems
    owner = User.find_by_slug!(params[:handle])
    rubygems = owner.rubygems.with_versions.preload(
      :linkset, :gem_download,
      most_recent_version: { dependencies: :rubygem, gem_download: nil }
    ).strict_loading

    respond_to do |format|
      format.json { render json: rubygems }
      format.yaml { render yaml: rubygems }
    end
  end

  protected

  def render_not_found
    render plain: response_with_mfa_warning("Owner could not be found."), status: :not_found
  end

  def email_param
    params.permit(:email).require(:email)
  end

  def ownership_params
    params.permit(:role)
  end
end
