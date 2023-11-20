module OIDC::Concerns::TrustedPublisherCreation
  extend ActiveSupport::Concern

  included do
    include SessionVerifiable
    verify_session_before

    before_action :set_trusted_publisher_type, only: %i[create]
    before_action :create_params, only: %i[create]
    before_action :set_page, only: :index
  end

  def set_trusted_publisher_type
    trusted_publisher_type = params.permit(create_params_key => :trusted_publisher_type).require(create_params_key).require(:trusted_publisher_type)

    @trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.polymorphic_name == trusted_publisher_type }

    return if @trusted_publisher_type
    redirect_back fallback_location: root_path, flash: { error: t("oidc.trusted_publisher.unsupported_type") }
  end
end
