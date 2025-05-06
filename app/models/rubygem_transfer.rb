class RubygemTransfer < ApplicationRecord
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  belongs_to :rubygem
  belongs_to :created_by, class_name: "User"
  belongs_to :transferable, polymorphic: true

  has_many :invites, -> { preload(:user) }, class_name: "RubygemTransferInvite", inverse_of: :rubygem_transfer, dependent: :destroy
  has_many :users, through: :invites

  accepts_nested_attributes_for :invites

  validate :rubygem_ownership

  before_save :sync_invites, if: :transferable_changed?

  def approved_invites
    invites.select(&:approved?)
  end

  def transfer!
    transaction do
      klass_for_transfer.transfer!(self)
      completed!
    end
  rescue ActiveRecord::ActiveRecordError => e
    self.status = :failed
    self.error = e.message
    save(validate: false)

    raise e
  end

  private

  def users_for_rubygem
    return User.none if rubygem.blank? || created_by.blank?
    User
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: rubygem.id })
      .where.not(ownerships: { user_id: created_by })
  end

  def sync_invites
    existing_invites = invites.index_by(&:user_id)
    self.invites = users_for_rubygem.map { existing_invites[it.id] || RubygemTransferInvite.new(user: it) }
  end

  def klass_for_transfer
    "RubygemTransfer#{transferable_type}".constantize
  end

  def rubygem_ownership
    return if RubygemPolicy.new(created_by, rubygem).transfer_gem?
    errors.add(:created_by, "does not have permission to transfer this gem")
  end
end
