class SearchesController < ApplicationController

  def show
    if params[:query]
      @gems = Rubygem.tire.search :page     => params[:page],
                                  :per_page => Rubygem.per_page,
                                  :load     => {:include => 'versions'} do |search|
        search.query do |s|
          s.filtered do |f|
            f.query  { |q| q.match :name, params[:query], :type => 'phrase_prefix', :operator => 'and' }
            f.filter :term, :indexed => true
          end
        end
        search.sort   { by :downloads, 'desc' }

        # STDOUT.puts search.to_curl if Rails.env.development?
      end

      @exact_match = Rubygem.name_is(params[:query]).with_versions.first

      redirect_to rubygem_path(@exact_match) if @exact_match && @gems.size == 1 && @gems.first.id == @exact_match.id
    end
  end

end
