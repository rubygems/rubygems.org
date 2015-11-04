class Api::V2::CompactIndexController < Api::BaseController
  def names
    names = Rubygem.order("name").pluck("name")
    render text: CompactIndex.names(names)
  end
end
