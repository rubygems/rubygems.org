class Version < ActiveRecord::Base
  belongs_to :rubygem

  attr_accessor :data
  before_validation :load_gem

  protected
    def load_gem
      temp = Tempfile.new("gem")

      File.open(temp.path, 'wb') do |f|
        f.write self.data.read
      end

      if File.size(temp.path).zero?
        self.error = "Empty gem cannot be processed."
        nil
      else
        temp
      end
    end

end
