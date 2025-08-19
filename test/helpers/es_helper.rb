module SearchKickHelper
  def self.included(base)
    base.setup :enable_callbacks
    base.teardown :disable_callbacks
  end

  def enable_callbacks
    Searchkick.enable_callbacks
  end

  def disable_callbacks
    Searchkick.disable_callbacks
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
    Searchkick.client.get index: Rubygem.searchkick_index.name, id: id
  end
end
