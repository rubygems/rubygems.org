class Api::V1::ArchiveController <  Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_with_otp
  before_action :find_rubygem

  def create
    authorize @rubygem, :archive?
    @rubygem.archive!(@api_key.user)

    render plain: response_with_mfa_warning("#{@rubygem.name} was succesfully archived.")
  end

  def destroy
    authorize @rubygem, :unarchive?
    @rubygem.unarchive!

    render plain: response_with_mfa_warning("#{@rubygem.name} was succesfully unarchived.")
  end
end
