name: "Setup rubygems.org"
description: "Setup steps for rubygems.org"
inputs:
  ruby-version:
    description: "Ruby version to use"
    required: true
  rubygems-version:
    description: "RubyGems version to use"
    required: true
runs:
  using: "composite"
  steps:
    - name: Install and start services
      shell: bash
      run: |
        docker-compose up -d
    - name: Wait for ES to boot
      shell: bash
      run: |
        timeout 300 bash -c "until curl --silent --output /dev/null http://localhost:9200/_cat/health?h=st; do printf '.'; sleep 5; done; printf '\n'"
    - uses: ruby/setup-ruby@360dc864d5da99d54fcb8e9148c14a84b90d3e88 # v1.165.1
      with:
        ruby-version: ${{ inputs.ruby-version }}
        bundler-cache: true
        rubygems: ${{ inputs.rubygems-version }}
    - name: Print bundle environment
      shell: bash
      run: bundle env
    - name: Prepare environment
      shell: bash
      run: |
        cp config/database.yml.sample config/database.yml
        bundle exec rake db:setup assets:precompile
