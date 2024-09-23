class Api::V1::WebHooksController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key
  before_action :find_rubygem_by_name, :set_url, except: :index

  def index
    authorize WebHook
    respond_to do |format|
      format.json { render json: @api_key.user.all_hooks }
      format.yaml { render yaml: @api_key.user.all_hooks }
    end
  end

  def create
    webhook = authorize @api_key.user.web_hooks.build(url: @url, rubygem: @rubygem)
    if webhook.save
      render(plain: webhook.success_message, status: :created)
    else
      render(plain: webhook.errors.full_messages, status: :conflict)
    end
  end

  def remove
    webhook = authorize @api_key.user.web_hooks.find_by_rubygem_id_and_url(@rubygem&.id, @url)
    if webhook&.destroy
      render(plain: webhook.removed_message)
    else
      render(plain: "No such webhook exists under your account.", status: :not_found)
    end
  end

  def fire
    webhook = @api_key.user.web_hooks.new(url: @url)
    @rubygem ||= Rubygem.find_by_name("gemcutter")

    authorize webhook

    response = webhook.fire(request.protocol.delete("://"), request.host_with_port,
                            @rubygem.most_recent_version, delayed: false)

    if response.fetch("status") == "success"
      render plain: webhook.deployed_message(@rubygem) + hook_relay_message(response)
    else
      render_bad_request webhook.failed_message(@rubygem) + hook_relay_message(response)
    end
  end

  private

  def find_rubygem_by_name
    @rubygem = Rubygem.find_by name: gem_name
    return if @rubygem || gem_name == WebHook::GLOBAL_PATTERN
    render plain: "This gem could not be found", status: :not_found
  end

  def set_url
    render_bad_request "URL was not provided" unless params[:url]
    @url = params[:url]
  end

  def hook_relay_message(response)
    status = response.fetch("status")
    msg = +""
    msg << "\nFailed with status #{status.inspect}: #{response['failure_reason']}" if status != "success"
    if response.key?("responses") && response["responses"].any?
      r = response.dig("responses", -1)
      msg << "\nError: #{r['error']}" if r["error"]
      msg << "\n\nResponse: #{r['code']}"
      r.fetch("headers", []).each do |k, v|
        msg << "\n#{k}: #{v}"
      end
      msg << "\n\n#{r['body']}"
    end

    msg
  end
end
