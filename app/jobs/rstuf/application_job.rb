class Rstuf::ApplicationJob < ApplicationJob
  before_enqueue do
    throw :abort unless Rstuf.enabled?
  end
end
