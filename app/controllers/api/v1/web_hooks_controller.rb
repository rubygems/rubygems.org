class Api::V1::WebHooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  before_filter :authenticate_with_api_key
  before_filter :verify_authenticated_user

  def index
    json = current_user.web_hooks.specific.group_by { |hook| hook.rubygem.name }
    json["all gems"] = current_user.web_hooks.global
    render :json => json
  end

  def create
    url      = params[:url]
    gem_name = params[:gem_name]
    rubygem  = Rubygem.find_by_name(gem_name)

    if rubygem.nil? && gem_name != WebHook::GLOBAL_PATTERN
      render :text   => "This gem could not be found",
             :status => :not_found
    else
      webhook = current_user.web_hooks.build(:url => url, :rubygem => rubygem)

      if webhook.save
        render :text   => webhook.success_message,
               :status => :created
      else
        render :text   => webhook.errors.full_messages,
               :status => :conflict
      end
    end
  end
end
