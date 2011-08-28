ActionController::Renderers.add :yaml do |obj, options|
  send_data obj.to_yaml, :type => 'text/yaml'
end
