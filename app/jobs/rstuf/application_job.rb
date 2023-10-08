module Rstuf
  class ApplicationJob < ::ApplicationJob
    before_enqueue do
      throw :abort unless Rstuf.enabled?
    end
  end
end
