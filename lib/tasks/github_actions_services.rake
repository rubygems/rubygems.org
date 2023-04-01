task github_actions_services: :environment do
  insert_into = lambda do |file, keypath|
    sh "yq", "--inplace", <<~YQ, file
      #{keypath}.services |=
        (
          load("./docker-compose.yml").services |
            with(
              .[] | select(has("environment"));
              .env = (.environment | map(split("=")) | map({ .[0]: .[1] } | to_entries) | flatten | from_entries)
            ) |
            del(.[].environment) |
            del(.[].network_mode)
      )
    YQ
  end

  insert_into[".github/workflows/test.yml", ".jobs.rails"]
  insert_into[".github/workflows/docker.yml", ".jobs.build"]
  insert_into[".github/workflows/erd.yml", ".jobs.erd"]
end
