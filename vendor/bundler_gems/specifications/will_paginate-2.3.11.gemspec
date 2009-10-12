# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{will_paginate}
  s.version = "2.3.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mislav Marohni\304\207", "PJ Hyett"]
  s.date = %q{2009-06-01}
  s.description = %q{The will_paginate library provides a simple, yet powerful and extensible API for ActiveRecord pagination and rendering of pagination links in ActionView templates.}
  s.email = %q{mislav.marohnic@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "CHANGELOG.rdoc"]
  s.files = ["CHANGELOG.rdoc", "LICENSE", "README.rdoc", "Rakefile", "examples/apple-circle.gif", "examples/index.haml", "examples/index.html", "examples/pagination.css", "examples/pagination.sass", "init.rb", "lib/will_paginate.rb", "lib/will_paginate/array.rb", "lib/will_paginate/collection.rb", "lib/will_paginate/core_ext.rb", "lib/will_paginate/finder.rb", "lib/will_paginate/named_scope.rb", "lib/will_paginate/named_scope_patch.rb", "lib/will_paginate/version.rb", "lib/will_paginate/view_helpers.rb", "test/boot.rb", "test/collection_test.rb", "test/console", "test/database.yml", "test/finder_test.rb", "test/fixtures/admin.rb", "test/fixtures/developer.rb", "test/fixtures/developers_projects.yml", "test/fixtures/project.rb", "test/fixtures/projects.yml", "test/fixtures/replies.yml", "test/fixtures/reply.rb", "test/fixtures/schema.rb", "test/fixtures/topic.rb", "test/fixtures/topics.yml", "test/fixtures/user.rb", "test/fixtures/users.yml", "test/helper.rb", "test/lib/activerecord_test_case.rb", "test/lib/activerecord_test_connector.rb", "test/lib/load_fixtures.rb", "test/lib/view_test_process.rb", "test/tasks.rake", "test/view_test.rb"]
  s.homepage = %q{http://github.com/mislav/will_paginate/wikis}
  s.rdoc_options = ["--main", "README.rdoc", "--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Most awesome pagination solution for Rails}
  s.test_files = ["test/boot.rb", "test/collection_test.rb", "test/console", "test/database.yml", "test/finder_test.rb", "test/fixtures/admin.rb", "test/fixtures/developer.rb", "test/fixtures/developers_projects.yml", "test/fixtures/project.rb", "test/fixtures/projects.yml", "test/fixtures/replies.yml", "test/fixtures/reply.rb", "test/fixtures/schema.rb", "test/fixtures/topic.rb", "test/fixtures/topics.yml", "test/fixtures/user.rb", "test/fixtures/users.yml", "test/helper.rb", "test/lib/activerecord_test_case.rb", "test/lib/activerecord_test_connector.rb", "test/lib/load_fixtures.rb", "test/lib/view_test_process.rb", "test/tasks.rake", "test/view_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
