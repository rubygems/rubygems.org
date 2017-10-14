require "rubygems"

# Assert we're using Psych
abort "ERROR! Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych
