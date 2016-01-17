require 'multi_json'
ActionController::Renderers.add :yaml do |obj, _|
  data = MultiJson.load(obj.to_json).to_yaml
  send_data data, type: 'text/yaml'
end
