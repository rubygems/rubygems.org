ActionController::Routing::Routes.draw do |map|
  map.resources :rubygems, :as => "gems"
  map.root :controller => "home", :action => "index"
end
