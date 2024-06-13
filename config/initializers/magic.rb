if ENV["MAGIC"].nil?
  # Be resilient to the gem being moved after installation, as is done in the docker image
  glob = File.join(
    Gem.loaded_specs.fetch("ruby-magic").full_gem_path,
    "ports",
    "*",
    "libmagic",
    Magic.version_string,
    "share",
    "misc",
    "magic.mgc"
  )
  ENV["MAGIC"] =
    begin
      Dir.glob(glob).sole
    rescue Enumerable::SoleItemExpectedError
      raise "Could not find magic.mgc in #{glob.inspect}\nTry running `bundle pristine ruby-magic` to fix this issue."
    end
end
