module ESHelper
  def import_and_refresh
    Rubygem.import force: true
    refresh_index
  end

  def refresh_index
    Rubygem.__elasticsearch__.refresh_index!
    # wait for indexing to finish
    Rubygem.__elasticsearch__.client.cluster.health wait_for_status: "yellow"
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
    refresh_index
    Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                    id: id
  end
end
