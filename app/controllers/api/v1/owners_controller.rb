class Api::V1::OwnersController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show gems]
  before_action :find_rubygem, except: :gems
  before_action :verify_gem_ownership, except: %i[show gems]
  before_action :verify_with_otp, only: %i[create destroy]

  def show
    respond_to do |format|
      format.json { render json: @rubygem.owners }
      format.yaml { render yaml: @rubygem.owners }
    end
  end

  def create
    owner = User.find_by_name(params[:email])
    if owner
      ownership = @rubygem.ownerships.new(user: owner, authorizer: @api_user)
      if ownership.save
        OwnersMailer.delay.ownership_confirmation(ownership.id)
        render plain: "Owner added successfully. A confirmation mail has been sent to #{owner.handle}'s email"
      else
        render plain: ownership.errors.full_messages.to_sentence, status: :unprocessable_entity
      end
    else
      render plain: "Owner could not be found.", status: :not_found
    end
  end

  def destroy
    owner = @rubygem.owners_including_unconfirmed.find_by_name(params[:email])
    if owner
      ownership = @rubygem.ownerships_including_unconfirmed.find_by!(user_id: owner.id)
      if ownership.destroy_and_notify
        render plain: "Owner removed successfully."
      else
        render plain: "Unable to remove owner.", status: :forbidden
      end
    else
      render plain: "Owner could not be found.", status: :not_found
    end
  end

  def gems
    user = User.find_by_slug(params[:handle])
    if user
      rubygems = user.rubygems.with_versions
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
    return if @api_user.rubygems.find_by_name(params[:rubygem_id])
    render plain: "You do not have permission to manage this gem.", status: :unauthorized
  end
end
