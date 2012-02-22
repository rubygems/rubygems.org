class Api::V1::WebHooksController < Api::BaseController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_with_api_key
  before_filter :verify_authenticated_user
  before_filter :find_rubygem_by_name, :except => :index
  respond_to :json, :xml, :yaml, :only => :index

  def index
    respond_with current_user.all_hooks
  end

  def create
    webhook = current_user.web_hooks.build(:url => @url, :rubygem => @rubygem)
    if webhook.save
      render(:text => webhook.success_message, :status => :created)
    else
      render(:text => webhook.errors.full_messages, :status => :conflict)
    end
  end

  def remove
    webhook = current_user.web_hooks.find_by_rubygem_id_and_url(@rubygem.try(:id), @url)
    if webhook.try(:destroy)
      render(:text => webhook.removed_message)
    else
      render(:text => "No such webhook exists under your account.", :status => :not_found)
    end
  end

  def fire
    webhook = current_user.web_hooks.new(:url => @url)
    @rubygem = Rubygem.find_by_name("gemcutter") unless @rubygem

    if webhook.fire(request.host_with_port, @rubygem, @rubygem.versions.most_recent, false)
      render :text => webhook.deployed_message(@rubygem)
    else
      render :text => webhook.failed_message(@rubygem), :status => :bad_request
    end
  end
end
