module SearchKickHelper
  def es_downloads(id)
    response = get_response(id)
    response["_source"]["downloads"]
  end

  def es_version_downloads(id)
    response = get_response(id)
    response["_source"]["version_downloads"]
  end

  def get_response(id)
    Searchkick.client.get index: Rubygem.search_index.name, id: id
  end
end
