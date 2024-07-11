class Api::V1::OwnersController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show gems]
  before_action :verify_user_api_key, except: %i[show gems]
  before_action :find_rubygem, except: :gems
  before_action :verify_api_key_gem_scope, except: %i[show gems]
  before_action :verify_gem_ownership, except: %i[show gems]
  before_action :verify_with_otp, except: %i[show gems]

  def show
    respond_to do |format|
      format.json { render json: @rubygem.owners }
      format.yaml { render yaml: @rubygem.owners }
    end
  end

  def create
    authorize @rubygem, :add_owner?
    return render_forbidden(t(:api_key_forbidden)) unless @api_key.can_add_owner?

    owner = User.find_by_name(email_param)
    if owner
      ownership = @rubygem.ownerships.new(user: owner, authorizer: @api_key.user)
      if ownership.save
        OwnersMailer.ownership_confirmation(ownership).deliver_later
        render plain: response_with_mfa_warning("#{owner.display_handle} was added as an unconfirmed owner. " \
                                                "Ownership access will be enabled after the user clicks on the " \
                                                "confirmation mail sent to their email.")
      else
        render plain: response_with_mfa_warning(ownership.errors.full_messages.to_sentence), status: :unprocessable_entity
      end
    else
      render plain: response_with_mfa_warning("Owner could not be found."), status: :not_found
    end
  end

  def destroy
    authorize @rubygem, :remove_owner?
    return render_forbidden(t(:api_key_forbidden)) unless @api_key.can_remove_owner?

    owner = @rubygem.owners_including_unconfirmed.find_by_name(email_param)
    if owner
      ownership = @rubygem.ownerships_including_unconfirmed.find_by(user_id: owner.id)
      if ownership.safe_destroy
        OwnersMailer.owner_removed(ownership.user_id, @api_key.user.id, ownership.rubygem_id).deliver_later
        render plain: response_with_mfa_warning("Owner removed successfully.")
      else
        render_forbidden response_with_mfa_warning("Unable to remove owner.")
      end
    else
      render plain: response_with_mfa_warning("Owner could not be found."), status: :not_found
    end
  end

  def gems
    user = User.find_by_slug(params[:handle])
    if user
      rubygems = user.rubygems.with_versions.preload(
        :linkset, :gem_download,
        most_recent_version: { dependencies: :rubygem, gem_download: nil }
      ).strict_loading
      respond_to do |format|
        format.json { render json: rubygems }
        format.yaml { render yaml: rubygems }
      end
    else
      render plain: "Owner could not be found.", status: :not_found
    end
  end

  protected

  def verify_gem_ownership
    return if @api_key.user.rubygems.find_by_name(params[:rubygem_id])
    render plain: response_with_mfa_warning("You do not have permission to manage this gem."), status: :unauthorized
  end

  def email_param
    params.permit(:email).require(:email)
  end
end
