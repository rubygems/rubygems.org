class UpdateRubygemSwiftype < Struct.new(:rubygem_id)
  def perform
    rubygem = Rubygem.find(rubygem_id)
    client = Swiftype::Client.new
    client.create_or_update_document(
      ENV['SWIFTYPE_ENGINE_SLUG'],
      Rubygem.model_name.downcase, 
      rubygem.to_st_hash
    )
  end
end
