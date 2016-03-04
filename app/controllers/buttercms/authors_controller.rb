class Buttercms::AuthorsController < Buttercms::BaseController
  def show
    @author = ButterCMS::Author.find(params[:slug], :include => :recent_posts)
  end
end
