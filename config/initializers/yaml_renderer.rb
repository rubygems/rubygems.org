ActionController::Renderers.add :yaml do |obj, options|
  data = JSON.load(obj.to_json(options)).to_yaml
  send_data data, type: 'text/yaml'
end
