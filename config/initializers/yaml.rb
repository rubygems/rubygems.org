if RUBY_VERSION > '1.9'
  require 'yaml'
  YAML::ENGINE.yamler = 'psych'
end
