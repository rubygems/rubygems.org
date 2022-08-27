module SearchKickHelper
  def import_and_refresh
    Rubygem.searchkick_reindex

    # wait for indexing to finish
    Searchkick.client.cluster.health wait_for_status: "yellow"
  end

  def es_downloads(id)
    response = get_response(id)
    response["_source"]["downloads"]
  end

  def es_version_downloads(id)
    response = get_response(id)
    response["_source"]["version_downloads"]
  end

  def get_response(id)
    Rubygem.searchkick_index.refresh
    Searchkick.client.get index: "rubygems-#{Rails.env}", id: id
  end
end
