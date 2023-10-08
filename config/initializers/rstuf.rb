require 'rstuf'

if ENV['RSTUF_API_URL']
  Rstuf.base_url = ENV['RSTUF_API_URL']
  Rstuf.enabled = true
end
