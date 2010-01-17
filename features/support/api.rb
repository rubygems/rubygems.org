module ApiHelpers
  def api_key_header
    header("HTTP_AUTHORIZATION", @api_key)
  end
end

World(ApiHelpers)
