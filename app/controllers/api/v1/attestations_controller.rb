class Api::V1::AttestationsController < Api::BaseController
  before_action :find_version

  def show
    respond_to do |format|
      format.json { render json: @version.attestations.pluck(:body) }
    end
  end

  private

  def find_version
    @version = Version.find_by(full_name: params[:id].delete_suffix(".json")) ||
      render(plain: t(:this_rubygem_could_not_be_found), status: :not_found)
  end
end
