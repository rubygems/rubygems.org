module ESHelper
  def import_and_refresh
    Rubygem.import force: true
    Rubygem.__elasticsearch__.refresh_index!
    # wait for indexing to finish
    Rubygem.__elasticsearch__.client.cluster.health wait_for_status: "yellow"
  end

  def es_downloads(id)
    response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                    type: "rubygem",
                                                    id: id
    response["_source"]["downloads"]
  end
end
