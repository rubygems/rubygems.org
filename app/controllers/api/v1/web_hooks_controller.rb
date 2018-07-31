class Api::V1::WebHooksController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_with_api_key
  before_action :verify_authenticated_user
  before_action :find_rubygem_by_name, :set_url, except: :index

  def index
    respond_to do |format|
      format.json { render json: @api_user.all_hooks }
      format.yaml { render yaml: @api_user.all_hooks }
    end
  end

  def create
    webhook = @api_user.web_hooks.build(url: @url, rubygem: @rubygem)
    if webhook.save
      render(plain: webhook.success_message, status: :created)
    else
      render(plain: webhook.errors.full_messages, status: :conflict)
    end
  end

  def remove
    webhook = @api_user.web_hooks.find_by_rubygem_id_and_url(@rubygem.try(:id), @url)
    if webhook.try(:destroy)
      render(plain: webhook.removed_message)
    else
      render(plain: "No such webhook exists under your account.", status: :not_found)
    end
  end

  def fire
    webhook = @api_user.web_hooks.new(url: @url)
    @rubygem ||= Rubygem.find_by_name("gemcutter")

    if webhook.fire(request.protocol.delete("://"), request.host_with_port, @rubygem,
      @rubygem.versions.most_recent, false)
      render plain: webhook.deployed_message(@rubygem)
    else
      render plain: webhook.failed_message(@rubygem), status: :bad_request
    end
  end

  private

  def set_url
    render plain: "URL was not provided", status: :bad_request unless params[:url]
    @url = params[:url]
  end
end
