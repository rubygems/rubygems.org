if ENV["MAGIC"].nil?
  # Be resilient to the gem being moved after installation, as is done in the docker image
  ENV["MAGIC"] = Dir.glob(File.join(
                            Gem.loaded_specs.fetch("ruby-magic").full_gem_path,
                            "ports",
                            "*",
                            "libmagic",
                            Magic.version_string,
                            "share",
                            "misc",
                            "magic.mgc"
                          )).sole
end
