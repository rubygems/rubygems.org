# frozen_string_literal: true

class Api::V1::OIDC::PendingTrustedPublishersController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key
  before_action :verify_with_otp
  before_action :set_trusted_publisher_type, only: %i[create]

  def index
    pending = policy_scope(OIDC::PendingTrustedPublisher)
      .unexpired.includes(:trusted_publisher).strict_loading
    render json: pending
  end

  def create
    pending = authorize @api_key.user.oidc_pending_trusted_publishers.build(
      create_params.merge(expires_at: 12.hours.from_now)
    )

    if pending.save
      render json: pending, status: :created
    else
      render json: { errors: pending.errors, status: :unprocessable_content }, status: :unprocessable_content
    end
  end

  private

  def set_trusted_publisher_type
    trusted_publisher_type = params.expect(:trusted_publisher_type)
    @trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.polymorphic_name == trusted_publisher_type }
    return if @trusted_publisher_type
    render json: { error: t("oidc.trusted_publisher.unsupported_type") }, status: :unprocessable_content
  end

  def create_params
    create_params = params.permit(
      :rubygem_name,
      :trusted_publisher_type,
      trusted_publisher: @trusted_publisher_type.permitted_attributes
    )
    create_params[:trusted_publisher_attributes] = create_params.delete(:trusted_publisher)
    create_params
  end
end
