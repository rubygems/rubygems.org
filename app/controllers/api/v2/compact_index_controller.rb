class Api::V2::CompactIndexController < Api::BaseController
  before_action :find_rubygem_by_name, only: [:info]

  def names
    names = Rubygem.order("name").pluck("name")
    render text: CompactIndex.names(names)
  end

  def info
    return unless stale?(@rubygem)
    info_params = @rubygem.compact_index_info
    render text: CompactIndex.info(info_params)
  end
end
