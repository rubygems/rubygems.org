module ApiHelpers
  def api_key_header
    page.driver.browser.header("Authorization", @api_key)
  end

  def marshal_body
    @_marshal_body ||= Marshal.load(page.source)
  end
end

World(ApiHelpers)
