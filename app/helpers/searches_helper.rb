module SearchesHelper

  def link_to_example_search(query)
    link_to query, search_url( :query => query, :anchor => 'tips' )
  end

end
