module RubygemTransferOrganization
  def self.transfer!(rubygem_transfer)
    rubygem = rubygem_transfer.rubygem
    organization = rubygem_transfer.transferable

    rubygem.organization = organization
    rubygem.save!
  end
end
