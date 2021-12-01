class OwnershipCallsController < ApplicationController
  before_action :find_rubygem, except: :index
  before_action :redirect_to_signin, unless: :signed_in?, except: :index
  before_action :render_forbidden, unless: :owner?, only: %i[create close]

  def index
    set_page
    @ownership_calls = OwnershipCall.opened.includes(:user, rubygem: %i[latest_version gem_download]).order(created_at: :desc)
      .page(@page)
      .per(Gemcutter::OWNERSHIP_CALLS_PER_PAGE)
  end

  def create
    @ownership_call = @rubygem.ownership_calls.new(user: current_user, note: params[:note])
    if @ownership_call.save
      redirect_to rubygem_adoptions_path(@rubygem), notice: t("ownership_calls.create.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_adoptions_path(@rubygem), alert: @ownership_call.errors.full_messages.to_sentence
    end
  end

  def close
    @ownership_call = @rubygem.ownership_call
    if @ownership_call&.close
      redirect_to rubygem_path(@rubygem), notice: t("ownership_calls.update.success_notice", gem: @rubygem.name)
    else
      redirect_to rubygem_adoptions_path(@rubygem), alert: t("try_again")
    end
  end
end
