class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :rubygem_id

  before_create :generate_token
  after_update :remove_unapproveds
  before_destroy :keep_last_owner

  def migrated?
    begin
      url = "http://#{rubygem.rubyforge_project || rubygem.name}.rubyforge.org/migrate-#{rubygem.name}.html"
      upload = open(url)
      if upload.string.strip == token
        update_attribute(:approved, true)
      end
    rescue *HTTP_ERRORS => ex
      logger.info "Problem when opening #{url}: #{ex}"
      false
    end
  end

  protected

    def generate_token
      self.token = ActiveSupport::SecureRandom.hex
    end

    def remove_unapproveds
      self.class.destroy_all(:rubygem_id => rubygem_id, :approved => false) if approved
    end

    def keep_last_owner
      if rubygem.owners.count == 1
        errors.add_to_base("Can't delete last owner of a gem.")
        false
      else
        true
      end
    end

end
