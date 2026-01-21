class OIDC::RubygemTrustedPublishersController < ApplicationController
  include OIDC::Concerns::TrustedPublisherCreation

  before_action :find_rubygem
  before_action :find_rubygem_trusted_publisher, except: %i[index new create]

  def index
    render OIDC::RubygemTrustedPublishers::IndexView.new(
      rubygem: @rubygem,
      trusted_publishers: @rubygem.oidc_rubygem_trusted_publishers.includes(:trusted_publisher).page(@page).strict_loading
    )
  end

  def new
    selected_trusted_publisher_type = nil
    if params[:trusted_publisher_type].present?
      selected_trusted_publisher_type = OIDC::TrustedPublisher.all.find { |type| type.url_identifier == params[:trusted_publisher_type] }
    end

    rubygem_trusted_publisher_instance = @rubygem.oidc_rubygem_trusted_publishers.new

    rubygem_trusted_publisher_instance.trusted_publisher = if selected_trusted_publisher_type
                                                             selected_trusted_publisher_type.new
                                                           else
                                                             OIDC::TrustedPublisher::GitHubAction.new
                                                           end

    render OIDC::RubygemTrustedPublishers::NewView.new(
      rubygem_trusted_publisher: rubygem_trusted_publisher_instance,
      trusted_publisher_types: OIDC::TrustedPublisher.all,
      selected_trusted_publisher_type: selected_trusted_publisher_type
    )
  end

  def create
    permitted_params = create_params
    trusted_publisher_type = @trusted_publisher_type
    specific_trusted_publisher_params = permitted_params[:trusted_publisher_attributes] || {}

    specific_trusted_publisher = trusted_publisher_type.build_trusted_publisher(specific_trusted_publisher_params)

    rubygem_trusted_publisher = @rubygem.oidc_rubygem_trusted_publishers.new(
      trusted_publisher: specific_trusted_publisher
    )
    trusted_publisher = authorize rubygem_trusted_publisher
    if trusted_publisher.save
      redirect_to rubygem_trusted_publishers_path(@rubygem.slug),
flash: { notice: t(".success") }
    else
      flash.now[:error] = trusted_publisher.errors.full_messages.to_sentence
      render OIDC::RubygemTrustedPublishers::NewView.new(
        rubygem_trusted_publisher: trusted_publisher,
        trusted_publisher_types: OIDC::TrustedPublisher.all,
        selected_trusted_publisher_type: trusted_publisher_type
      ), status: :unprocessable_content
    end
  end

  def destroy
    if @rubygem_trusted_publisher.destroy
      redirect_to rubygem_trusted_publishers_path(@rubygem.slug), flash: { notice: t(".success") }
    else
      redirect_back_or_to(rubygem_trusted_publishers_path(@rubygem.slug),
flash: { error: @rubygem_trusted_publisher.errors.full_messages.to_sentence })
    end
  end

  private

  def create_params
    params.expect(
      create_params_key => [:trusted_publisher_type,
                            trusted_publisher_attributes: @trusted_publisher_type.permitted_attributes]
    )
  end

  def create_params_key = :oidc_rubygem_trusted_publisher

  def find_rubygem
    super
    authorize @rubygem, :configure_trusted_publishers?
  end

  def find_rubygem_trusted_publisher
    @rubygem_trusted_publisher = authorize @rubygem.oidc_rubygem_trusted_publishers.find(params[:id])
  end
end
