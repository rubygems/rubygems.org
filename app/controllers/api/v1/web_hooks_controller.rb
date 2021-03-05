class Api::V1::WebHooksController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :render_api_key_forbidden, if: :api_key_unauthorized?
  before_action :find_rubygem_by_name, :set_url, except: :index

  def index
    respond_to do |format|
      format.json { render json: @api_key.user.all_hooks }
      format.yaml { render yaml: @api_key.user.all_hooks }
    end
  end

  def create
    webhook = @api_key.user.web_hooks.build(url: @url, rubygem: @rubygem)
    if webhook.save
      render(plain: webhook.success_message, status: :created)
    else
      render(plain: webhook.errors.full_messages, status: :conflict)
    end
  end

  def remove
    webhook = @api_key.user.web_hooks.find_by_rubygem_id_and_url(@rubygem&.id, @url)
    if webhook&.destroy
      render(plain: webhook.removed_message)
    else
      render(plain: "No such webhook exists under your account.", status: :not_found)
    end
  end

  def fire
    webhook = @api_key.user.web_hooks.new(url: @url)
    @rubygem ||= Rubygem.find_by_name("gemcutter")

    if webhook.fire(request.protocol.delete("://"), request.host_with_port, @rubygem,
      @rubygem.versions.most_recent, delayed: false)
      render plain: webhook.deployed_message(@rubygem)
    else
      render plain: webhook.failed_message(@rubygem), status: :bad_request
    end
  end

  private

  def find_rubygem_by_name
    @rubygem = Rubygem.find_by name: gem_name
    return if @rubygem || gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end

  def set_url
    render plain: "URL was not provided", status: :bad_request unless params[:url]
    @url = params[:url]
  end

  def api_key_unauthorized?
    !@api_key.can_access_webhooks?
  end
end
