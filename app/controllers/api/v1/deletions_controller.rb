class Api::V1::DeletionsController < Api::BaseController
  skip_before_action :verify_authenticity_token, :only => [:create, :destroy]

  before_action :authenticate_with_api_key, :only => [:create, :destroy]
  before_action :verify_authenticated_user, :only => [:create, :destroy]
  before_action :find_rubygem_by_name,      :only => [:create, :destroy]
  before_action :validate_gem_and_version,  :only => [:create]

  def create
    if @version.indexed?
      @version.yank!
      current_user.deletions.create! rubygem: @version.rubygem.name, number: @version.number, platform: @version.platform
      StatsD.increment 'yank.success'
      render :text => "Successfully yanked gem: #{@version.to_title}"
    else
      StatsD.increment 'yank.failure'
      render :text => "The version #{params[:version]} has already been yanked.", :status => :unprocessable_entity
    end
  end

  def destroy
    render text: "Unyanking of gems is no longer supported.", status: :gone
  end

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render :text => "This gem does not exist.", :status => :not_found
    elsif !@rubygem.owned_by?(current_user)
      render :text => "You do not have permission to yank this gem.", :status => :forbidden
    else
      begin
        slug = params[:platform].blank? ? params[:version] : "#{params[:version]}-#{params[:platform]}"
        @version = Version.find_from_slug!(@rubygem, slug)
      rescue ActiveRecord::RecordNotFound
        render :text => "The version #{params[:version]} does not exist.", :status => :not_found
      end
    end
  end
end
