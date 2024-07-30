class OIDC::PendingTrustedPublishersController < ApplicationController
  include OIDC::Concerns::TrustedPublisherCreation

  before_action :find_pending_trusted_publisher, only: %i[destroy]

  def index
    trusted_publishers = policy_scope(OIDC::PendingTrustedPublisher)
      .unexpired.includes(:trusted_publisher)
      .order(:rubygem_name, :created_at).page(@page).strict_loading
    render OIDC::PendingTrustedPublishers::IndexView.new(
      trusted_publishers:
    )
  end

  def new
    pending_trusted_publisher = current_user.oidc_pending_trusted_publishers.new(trusted_publisher: OIDC::TrustedPublisher::GitHubAction.new)
    render OIDC::PendingTrustedPublishers::NewView.new(
      pending_trusted_publisher:
    )
  end

  def create
    trusted_publisher = authorize current_user.oidc_pending_trusted_publishers.new(
      create_params.merge(
        expires_at: 12.hours.from_now
      )
    )

    if trusted_publisher.save
      redirect_to profile_oidc_pending_trusted_publishers_path, flash: { notice: t(".success") }
    else
      flash.now[:error] = trusted_publisher.errors.full_messages.to_sentence
      render OIDC::PendingTrustedPublishers::NewView.new(
        pending_trusted_publisher: trusted_publisher
      ), status: :unprocessable_entity
    end
  end

  def destroy
    if @pending_trusted_publisher.destroy
      redirect_to profile_oidc_pending_trusted_publishers_path, flash: { notice: t(".success") }
    else
      redirect_back fallback_location: profile_oidc_pending_trusted_publishers_path,
                    flash: { error: @pending_trusted_publisher.errors.full_messages.to_sentence }
    end
  end

  private

  def create_params
    params.permit(
      create_params_key => [
        :rubygem_name,
        :trusted_publisher_type,
        { trusted_publisher_attributes: @trusted_publisher_type.permitted_attributes }
      ]
    ).require(create_params_key)
  end

  def create_params_key = :oidc_pending_trusted_publisher

  def find_pending_trusted_publisher
    @pending_trusted_publisher = authorize current_user.oidc_pending_trusted_publishers.find(params.permit(:id).require(:id))
  end
end
