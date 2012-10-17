class Api::V1::DependenciesController < Api::BaseController
  def index
    render :text => "Dependency API disabled temporarily for performance reasons", :status => 503 and return

    gem_list = (params[:gems] || '').split(',')

    if gem_list.size <= Dependency::LIMIT
      render :text => Marshal.dump(Dependency.for(gem_list))
    else
      render :text   => "Too many gems to resolve, please request less than #{Dependency::LIMIT} gems",
             :status => :request_entity_too_large
    end
  end
end
