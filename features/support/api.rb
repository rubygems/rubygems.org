module ApiHelpers
  def api_key_header
    header("HTTP_AUTHORIZATION", @api_key)
  end

  def marshal_body
    @_marshal_body ||= Marshal.load(response.body)
  end
end

World(ApiHelpers)
