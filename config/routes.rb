ActionController::Routing::Routes.draw do |map|
  map.resources :gems
  map.root :controller => "home", :action => "index"
end
