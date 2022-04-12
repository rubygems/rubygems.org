namespace :linkset do
  def invalid_links
    Linkset.where.not("home ~* ? or home = ''",
      '\Ahttps?:\/\/([^\s:@]+:[^\s:@]*@)?[A-Za-z\d\-]+(\.[A-Za-z\d\-]+)+\.?(:\d{1,5})?([\/?]\S*)?')
  end

  desc "Remove invalid URLs in linkset"
  task clean: :environment do
    Linkset.transaction do
      puts "Removing invalid home urls..."
      invalid_links.each do |link|
        link.update_attribute("home", link.home.strip.to_s)
      end
      affected = invalid_links.update_all(["home = ?", nil])
      puts "Successfully removed #{affected} urls in home"
    end
  rescue StandardError
    puts "Error: Couldn't update urls"
  end
end
