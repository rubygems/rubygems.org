class ArchiveController < ApplicationController
  include SessionVerifiable

  verify_session_before
  before_action :find_rubygem
  before_action :verify_mfa_requirement

  def create
    authorize @rubygem, :archive?
    @rubygem.archive!(current_user)

    redirect_to rubygem_path(@rubygem), notice: t(".success")
  end

  def destroy
    authorize @rubygem, :unarchive?
    @rubygem.unarchive!

    redirect_to rubygem_path(@rubygem), notice: t(".success")
  end

  private

  def verify_mfa_requirement
    return if @rubygem.mfa_requirement_satisfied_for?(current_user)
    index_with_error t("owners.mfa_required"), :forbidden
  end
end
