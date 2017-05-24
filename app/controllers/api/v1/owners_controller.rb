class Api::V1::OwnersController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: %i[create destroy]
  before_action :authenticate_with_api_key, except: %i[show gems]
  before_action :verify_authenticated_user, except: %i[show gems]
  before_action :find_rubygem, except: :gems
  before_action :verify_gem_ownership, except: %i[show gems]

  def show
    owners = @rubygem.owners
    respond_to_block(owners)
  end

  def create
    owner = User.find_by_name(params[:email])
    if owner
      @rubygem.ownerships.create(user: owner)
      render plain: 'Owner added successfully.'
    else
      render plain: 'Owner could not be found.', status: :not_found
    end
  end

  def destroy
    owner = @rubygem.owners.find_by_name(params[:email])
    if owner
      ownership = @rubygem.ownerships.find_by(user_id: owner.id)
      if ownership.try(:safe_destroy)
        render plain: "Owner removed successfully."
      else
        render plain: 'Unable to remove owner.', status: :forbidden
      end
    else
      render plain: 'Owner could not be found.', status: :not_found
    end
  end

  def gems
    user = User.find_by_slug!(params[:handle])
    if user
      rubygems = user.rubygems.with_versions
      respond_to_block(rubygems)
    else
      render plain: "Owner could not be found.", status: :not_found
    end
  end

  protected

  def verify_gem_ownership
    return if current_user.rubygems.find_by_name(params[:rubygem_id])
    render plain: 'You do not have permission to manage this gem.', status: :unauthorized
  end

  private

  def respond_to_block(data)
    respond_to do |format|
      format.json { render json: data }
      format.yaml { render yaml: data }
    end
  end
end
