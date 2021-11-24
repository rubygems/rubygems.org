# frozen_string_literal: true

#======================================================================================
# HOW TO USE THIS
# This task assumes that you have rubygems loaded into your database, but no users
# The task will create users and assign them to the most downloaded gems
#
# To clear your database and load the latest rubygems data dump:
# 💻 In your rubygems.org directory run ... (optional)
#    rails db:reset
# 💻 Navigate to Rubygems Data Dump and download one of the dumps (https://rubygems.org/pages/data)
# 💻 In your rubygems.org direction run ...
#    ./script/load-pg-dump -d rubygems_development ~/Downloads/public_postgresql.tar
# 💻 In your rubygems.org direction run ...
#    rake gem_owners:seed
#======================================================================================

namespace :gem_owners do
  task seed: :environment do
    people = [
      {
        email: "sandi@metz.com",
        password: "yellow-bananas-111",
        handle: "sandi",
      },
      {
        email: "katrina@owen.com",
        password: "red-bananas-111",
        handle: "katrina",
      },
      {
        email: "jen@shenny.com",
        password: "black-berries-111",
        handle: "jenshenny",
      },
      {
        email: "betty@li.com",
        password: "poop-berries-111",
        handle: "betty",
      },
      {
        email: "panda@bear.com",
        password: "blue-berries-111",
        handle: "panda",
      },
      {
        email: "power@rangers.com",
        password: "green-ranger-111",
        handle: "greenranger",
      },
      {
        email: "squid@games.com",
        password: "so-squiddy-111",
        handle: "squid",
      },
    ]

    puts
    puts "*" * 32
    puts "Let's seed this database! 🌱 🚰"
    puts "*" * 32
    puts
    print("Seeding Users")
    puts

    people.each do |person|
      print "🧒"
      User.create(
        email: person[:email],
        password: person[:password],
        handle: person[:handle],
        email_confirmed: true
      )
    end

    users = User.all
    rubygems = Rubygem.by_downloads.limit((users.count * 10) + 1)
    count = 1

    puts
    puts
    print("Assigning gem owners")
    puts
    users.each do |user|
      # Assign all users to the same gem
      print "💎"
      Ownership.create_confirmed(rubygems[0], user)

      10.times do
        print "💎"
        Ownership.create_confirmed(rubygems[count], user)

        count += 1
      end
    end
  end
end
