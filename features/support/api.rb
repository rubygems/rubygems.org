module ApiHelpers
  def api_key_header
    header("Authorization", @api_key)
  end
end

World(ApiHelpers)
