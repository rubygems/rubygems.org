class Api::V1::WebHooksController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_with_api_key
  before_action :verify_authenticated_user
  before_action :find_rubygem_by_name, except: :index

  def index
    respond_to do |format|
      format.json { render json: current_user.all_hooks }
      format.yaml { render yaml: current_user.all_hooks }
    end
  end

  def create
    webhook = current_user.web_hooks.build(url: @url, rubygem: @rubygem)
    if webhook.save
      render(plain: webhook.success_message, status: :created)
    else
      render(plain: webhook.errors.full_messages, status: :conflict)
    end
  end

  def remove
    webhook = current_user.web_hooks.find_by_rubygem_id_and_url(@rubygem.try(:id), @url)
    if webhook.try(:destroy)
      render(plain: webhook.removed_message)
    else
      render(plain: "No such webhook exists under your account.", status: :not_found)
    end
  end

  def fire
    rubygem = @rubygem || Rubygem.find_by(name: 'gemcutter')
    webhook = current_user.web_hooks.find_or_initialize_by(rubygem: rubygem, url: @url)
    if webhook.disabled?
      webhook.re_enable
      message = webhook.re_enable_message
    end

    protocol = request.protocol.delete("://")
    if webhook.fire(protocol, request.host_with_port, rubygem,
      rubygem.versions.most_recent, false)
      message = message ? message + webhook.deployed_message(rubygem) : webhook.deployed_message(rubygem)
      render plain: message
    else
      message = message ? message + webhook.failed_message(rubygem) : webhook.failed_message(rubygem)
      render plain: message, status: :bad_request
    end
  end
end
