BetterHtml.configure do |config|
  config.template_exclusion_filter = proc { |filename|
    filename.include?("avo") || filename.include?("/railties-")
  }
end
