class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate, :only => :create
  before_filter :redirect_to_root, :only => [:token, :mine, :edit, :update], :unless => :signed_in?
  before_filter :load_gem, :only => [:edit, :update]

  def new
  end

  def migrate
  end

  def search
  end

  def mine
    @gems = current_user.rubygems
  end

  def index
    @gems = Rubygem.by_name(:asc)
  end

  def show
    @gem = Rubygem.find(params[:id])
  end

  def edit
  end

  def token
    @gem = Rubygem.find(params[:id])
    response.content_type = "text/plain"
    render :text => @gem.token
  end

  def update
    if @linkset.update_attributes(params[:linkset])
      redirect_to rubygem_path(@gem)
      flash[:success] = "Gem links updated."
    else
      render :edit
    end
  end

  def create
    temp = Tempfile.new("gem")
    temp.write request.body.read
    temp.flush
    temp.close

    spec = Rubygem.pull_spec(temp.path)

    if spec.nil?
      render :text => "Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid.", :status => 422
      return
    end

    rubygem = Rubygem.find_or_initialize_by_name(spec.name)

    if !rubygem.new_record? && !rubygem.owned_by?(current_user)
      render :text => "You do not have permission to push to this gem.", :status => 403
      return
    end

    rubygem.spec = spec
    rubygem.path = temp.path
    rubygem.ownerships.build(:user => current_user, :approved => true)
    rubygem.save
    render :text => "Successfully registered new gem: #{rubygem}"
  end

  protected
    def authenticate
      @_current_user = User.find_by_api_key(request.headers["HTTP_AUTHORIZATION"])
      if current_user.nil?
        render :text => "Access Denied. Please sign up for an account at http://gemcutter.org", :status => 401
      elsif !current_user.email_confirmed
        render :text => "Access Denied. Please confirm your Gemcutter account.", :status => 403
      end
    end

    def load_gem
      @gem = Rubygem.find(params[:id])

      if !@gem.owned_by?(current_user)
        flash[:warning] = "You do not have permission to edit this gem."
        redirect_to root_url
      end

      @linkset = @gem.linkset
    end
end
