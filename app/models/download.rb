class Download < ActiveRecord::Base
  include Pacecar unless Rails.env.maintenance?
  belongs_to :version, :counter_cache => true

  def after_create
    version.rubygem.increment!(:downloads)
  end
end
