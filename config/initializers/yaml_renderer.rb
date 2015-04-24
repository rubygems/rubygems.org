require 'minitest'

ActionController::Renderers.add :yaml do |obj, options|
  data = MultiJson.load(obj.to_json).to_yaml
  send_data data, type: 'text/yaml'
end
