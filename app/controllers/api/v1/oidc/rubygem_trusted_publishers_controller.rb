class Api::V1::OIDC::RubygemTrustedPublishersController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key

  before_action :find_rubygem

  before_action :verify_api_key_gem_scope
  before_action :verify_with_otp
  before_action :verify_mfa_requirement
  before_action :verify_api_key_scope

  before_action :render_forbidden, unless: :owner?
  before_action :find_rubygem_trusted_publisher, except: %i[index create]
  before_action :set_trusted_publisher_type, only: %i[create]

  def index
    render json: @rubygem.oidc_rubygem_trusted_publishers.strict_loading
      .includes(:trusted_publisher)
  end

  def show
    render json: @rubygem_trusted_publisher
  end

  def create
    trusted_publisher = @rubygem.oidc_rubygem_trusted_publishers.build(
      create_params
    )

    if trusted_publisher.save
      render json: trusted_publisher, status: :created
    else
      render json: { errors: trusted_publisher.errors, status: :unprocessable_entity }, status: :unprocessable_entity
    end
  end

  def destroy
    @rubygem_trusted_publisher.destroy!
  end

  private

  def verify_api_key_scope
    render_api_key_forbidden unless @api_key.can_configure_trusted_publishers?
  end

  def find_rubygem_trusted_publisher
    @rubygem_trusted_publisher = @rubygem.oidc_rubygem_trusted_publishers.find(params.permit(:id).require(:id))
  end

  def set_trusted_publisher_type
    trusted_publisher_type = params.permit(:trusted_publisher_type).require(:trusted_publisher_type)

    @trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.polymorphic_name == trusted_publisher_type }

    return if @trusted_publisher_type

    render json: { error: t("oidc.trusted_publisher.unsupported_type") }, status: :unprocessable_entity
  end

  def create_params
    create_params = params.permit(
      :trusted_publisher_type,
      trusted_publisher: @trusted_publisher_type.permitted_attributes
    )
    create_params[:trusted_publisher_attributes] = create_params.delete(:trusted_publisher)
    create_params
  end
end
