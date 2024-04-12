class OIDC::RubygemTrustedPublishersController < ApplicationController
  include OIDC::Concerns::TrustedPublisherCreation

  before_action :find_rubygem
  before_action :render_forbidden, unless: :owner?
  before_action :find_rubygem_trusted_publisher, except: %i[index new create]

  def index
    render OIDC::RubygemTrustedPublishers::IndexView.new(
      rubygem: @rubygem,
      trusted_publishers: @rubygem.oidc_rubygem_trusted_publishers.includes(:trusted_publisher).page(@page).strict_loading
    )
  end

  def new
    render OIDC::RubygemTrustedPublishers::NewView.new(
      rubygem_trusted_publisher: @rubygem.oidc_rubygem_trusted_publishers.new(trusted_publisher: gh_actions_trusted_publisher)
    )
  end

  def create
    trusted_publisher = @rubygem.oidc_rubygem_trusted_publishers.new(
      create_params
    )

    if trusted_publisher.save
      redirect_to rubygem_trusted_publishers_path(@rubygem.slug), flash: { notice: t(".success") }
    else
      flash.now[:error] = trusted_publisher.errors.full_messages.to_sentence
      render OIDC::RubygemTrustedPublishers::NewView.new(
        rubygem_trusted_publisher: trusted_publisher
      ), status: :unprocessable_entity
    end
  end

  def destroy
    if @rubygem_trusted_publisher.destroy
      redirect_to rubygem_trusted_publishers_path(@rubygem.slug), flash: { notice: t(".success") }
    else
      redirect_back fallback_location: rubygem_trusted_publishers_path(@rubygem.slug),
                    flash: { error: @rubygem_trusted_publisher.errors.full_messages.to_sentence }
    end
  end

  private

  def create_params
    params.permit(
      create_params_key => [
        :trusted_publisher_type,
        { trusted_publisher_attributes: @trusted_publisher_type.permitted_attributes }
      ]
    ).require(create_params_key)
  end

  def create_params_key = :oidc_rubygem_trusted_publisher

  def find_rubygem_trusted_publisher
    @rubygem_trusted_publisher = @rubygem.oidc_rubygem_trusted_publishers.find(params_fetch(:id))
  end

  def gh_actions_trusted_publisher
    github_params = helpers.github_params(@rubygem)

    publisher = OIDC::TrustedPublisher::GitHubAction.new
    if github_params
      publisher.repository_owner = github_params[:user]
      publisher.repository_name = github_params[:repo]
      publisher.workflow_filename = workflow_filename(publisher.repository)
    end
    publisher
  end

  def workflow_filename(repo)
    paths = Octokit.contents(repo, path: ".github/workflows").lazy.select { _1.type == "file" }.map(&:name).grep(/\.ya?ml\z/)
    paths.max_by { |path| [path.include?("release"), path.include?("push")].map! { (_1 && 1) || 0 } }
  rescue Octokit::NotFound
    nil
  end
end
