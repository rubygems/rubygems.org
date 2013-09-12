class SearchesController < ApplicationController

  # Handle search engine not being available
  #
  rescue_from Errno::EHOSTUNREACH, Errno::ECONNREFUSED, SocketError do |error|
    flash.now[:failure] = "Sorry, search is not available at the moment." if params[:query]
    render :show, :status => :internal_server_error
  end

  # Indicate incorrect query to the user
  #
  rescue_from Tire::Search::SearchRequestFailed do |error|
    flash.now[:failure] = "Sorry, your query is incorrect." if error.message =~ /SearchParseException/ && params[:query]
    render :show, :status => :internal_server_error
  end

  def show
    if params[:query].present?
      @gems = Rubygem.tire.search :page     => params[:page],
                                  :per_page => Rubygem.per_page,
                                  :load     => {:include => 'versions'} do |search|

        search.query do |s|
          s.filtered do |f|
            f.query  do |q|
              q.boolean do |it|
                it.should { |q| q.match 'name.raw', params[:query], :boost => 500 }
                it.should { |q| q.match :name, params[:query], :type => 'phrase_prefix', :operator => 'and', :boost => 100 }
                it.should { |q| q.string params[:query], :default_operator => 'and' }
              end
            end
            f.filter :term, :indexed => true
          end
        end

        search.sort   do
          by 'downloads', :desc
          by 'name.raw',  :asc
        end

        # STDOUT.puts search.to_curl if Rails.env.development?
      end

      @exact_match = Rubygem.name_is(params[:query]).with_versions.first

      redirect_to rubygem_path(@exact_match) if @exact_match && @gems.size == 1 && @gems.first.id == @exact_match.id
    end
  end

end
