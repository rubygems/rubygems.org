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
    selected_trusted_publisher_type = nil
    if params[:trusted_publisher_type].present?
      selected_trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.polymorphic_name == params[:trusted_publisher_type] }
    end

    pending_trusted_publisher = current_user.oidc_pending_trusted_publishers.new
    pending_trusted_publisher.trusted_publisher = if selected_trusted_publisher_type
                                                     selected_trusted_publisher_type.new
                                                   else
                                                     OIDC::TrustedPublisher::GitHubAction.new
                                                   end

    render OIDC::PendingTrustedPublishers::NewView.new(
      pending_trusted_publisher: pending_trusted_publisher,
      trusted_publisher_types: OIDC::TrustedPublisher.all,
      selected_trusted_publisher_type: selected_trusted_publisher_type
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
      selected_trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.polymorphic_name == create_params[:trusted_publisher_type] }
      render OIDC::PendingTrustedPublishers::NewView.new(
        pending_trusted_publisher: trusted_publisher,
        trusted_publisher_types: OIDC::TrustedPublisher.all,
        selected_trusted_publisher_type: selected_trusted_publisher_type
      ), status: :unprocessable_content
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
    params.expect(
      create_params_key => [
        :rubygem_name,
        :trusted_publisher_type,
        trusted_publisher_attributes: @trusted_publisher_type.permitted_attributes
      ]
    )
  end

  def create_params_key = :oidc_pending_trusted_publisher

  def find_pending_trusted_publisher
    @pending_trusted_publisher = authorize current_user.oidc_pending_trusted_publishers.find(params[:id])
  end
end
