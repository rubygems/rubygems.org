# frozen_string_literal: true

module OIDC::Concerns::TrustedPublisherCreation
  extend ActiveSupport::Concern

  included do
    include SessionVerifiable

    verify_session_before

    before_action :set_trusted_publisher_type, only: %i[create]
    before_action :set_selected_trusted_publisher_type, only: %i[new create]
    before_action :create_params, only: %i[create]
    before_action :set_page, only: :index
  end

  def set_trusted_publisher_type
    trusted_publisher_type = params.expect(create_params_key => :trusted_publisher_type).require(:trusted_publisher_type)

    @trusted_publisher_type = OIDC::TrustedPublisher.find_by_polymorphic_name(trusted_publisher_type)

    return if @trusted_publisher_type
    redirect_back_or_to(root_path, flash: { error: t("oidc.trusted_publisher.unsupported_type") })
  end

  private

  def set_selected_trusted_publisher_type
    @selected_trusted_publisher_type = OIDC::TrustedPublisher.find_by_url_identifier(params[:trusted_publisher_type]) || OIDC::TrustedPublisher::GitHubAction
  end

  def initialize_trusted_publisher(container)
    instance = container.new
    instance.trusted_publisher = @selected_trusted_publisher_type.new
    instance
  end
end
