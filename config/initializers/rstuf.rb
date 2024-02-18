require 'rstuf'

if ENV['RSTUF_API_URL'].presence
  Rstuf.base_url = ENV['RSTUF_API_URL']
  Rstuf.enabled = true
  Rstuf.wait_for = 10.seconds
end
