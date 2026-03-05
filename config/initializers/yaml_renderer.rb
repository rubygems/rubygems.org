# frozen_string_literal: true

ActionController::Renderers.add :yaml do |obj, _|
  data = JSON.load(obj.to_json).to_yaml
  send_data data, type: 'text/yaml'
end
