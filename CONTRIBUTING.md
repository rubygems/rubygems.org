Contribution Guidelines
=======================

From the [Rubinius](http://rubini.us/) contribution page:

> Writing code and participating should be fun, not an exercise in
> perseverance. Stringent commit polices, for whatever their other
> qualities may bring, also mean longer turnaround times.

Submit a patch and once it’s accepted, you’ll get commit access to the
repository. Feel free to fork the repository and send a pull request,
once it’s merged in you’ll get added. If not, feel free to bug
[qrush](http://github.com/qrush) about it.

Also, if you’re hacking on RubyGems.org, hop in `#rubygems` on
`irc.freenode.net`! Chances are someone else will be around to answer
questions or bounce ideas off of.

How To Contribute
-----------------

* Follow the steps described in [Development Setup](#development-setup)
* Create a topic branch: `git checkout -b awesome_feature`
* Commit your changes
* Keep up to date: `git fetch && git rebase origin/master`

Once you’re ready:

* Fork the project on GitHub
* Add your repository as a remote: `git remote add your_remote your_repo`
* Push up your branch: `git push your_remote awesome_feature`
* Create a Pull Request for the topic branch, asking for review.

Once it’s accepted:

* If you want access to the core repository feel free to ask! Then you
can change origin to point to the Read+Write URL:

```
git remote set-url origin git@github.com:rubygems/rubygems.org.git
```

Otherwise, you can continue to hack away in your own fork.

If you’re looking for things to hack on, please check
[GitHub Issues](http://github.com/rubygems/rubygems.org/issues). If you’ve
found bugs or have feature ideas don’t be afraid to pipe up and ask the
[mailing list](http://groups.google.com/group/rubygems-org) or IRC channel
(`#rubygems` on `irc.freenode.net`) about them.

Acceptance
----------

**Contributions WILL NOT be accepted without tests.**

If you haven't tested before, start reading up in the `test/` directory to see
what's going on. If you've got good links regarding TDD or testing in general
feel free to add them here!

Branching
---------

For your own development, use the topic branches. Basically, cut each
feature into its own branch and send pull requests based off those.

The master branch is the main production branch. **Always** should be
fast-forwardable.

Development Setup
-----------------

This page is for setting up Rubygems on a local development machine to
contribute patches/fixes/awesome stuff. **If you need to host your own
gem server, please consider checking out
[Geminabox](http://github.com/geminabox/geminabox). It’s a lot simpler
than Rubygems and may suit your organization’s needs better.**

#### Environment (OS X)

* Use Ruby 2.1.6
* Use Rubygems 2.4.5
* Install bundler: `gem install bundler`
* Install [redis](http://github.com/antirez/redis),
    **version 2.0 or higher**. If you have homebrew,
    do `brew install redis -H`, if you use macports,
    do `sudo port install redis`.
* Rubygems is configured to use PostgreSQL (>= 8.4.x).
  * Install with: `brew install postgres`
  * Initialize the database and start the DB server
    ```shell
   initdb /usr/local/var/postgres -E utf8
   pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
   ```
* If you want to use MySQL instead
  * Install with: `brew install mysql`
  * Start the DB server with: `sudo /usr/local/mysql/support-files/mysql.server start`

#### Environment (Linux - Debian/Ubuntu)

* Use Ruby 2.1.6 `apt-get install ruby2.1`
  * Or install via [alternate methods](http://www.ruby-lang.org/en/downloads/)
* Use Rubygems 2.4.5
* Install bundler: `gem install bundler`
* Install Redis: `apt-get install redis-server`
* Install PostgreSQL: `apt-get install postgresql postgresql-server-dev-all`
  * Help to setup database <https://wiki.debian.org/PostgreSql>

#### Getting the code

* Clone the repo: `git clone git://github.com/rubygems/rubygems.org`
* Move into your cloned rubygems directory if you haven’t already:
    `cd rubygems.org`
* If you're using MySQL - replace `pg` with `mysql2` in the Gemfile
  * `sed -i "s/gem 'pg'/gem 'mysql2'/" Gemfile`
* Install dependencies:
    `bundle install`

#### Setting up the database

* Get set up: `./script/setup`
* Run the database rake tasks if needed:
    `bundle exec rake db:create:all db:drop:all db:setup db:test:prepare --trace`

#### Running tests

* Start redis: `redis-server`
* Run the tests: `bundle exec rake`

#### Running RuboCop

We use RuboCop to enforce a consistent coding style throughout the project.
Please ensure any changes you make conform to our style standards or else the
build will fail.

    bundle exec rake rubocop

If you'd like RuboCop to attempt to automatically fix your style offenses, you
can try running:

    bundle exec rake rubocop:auto_correct

#### Importing gems into the database

* Import gems into the database with Rake task.
    `bundle exec rake gemcutter:import:process vendor/cache`
    * _To import a small set of gems you can point the import process to any
        gems cache directory, like a very small `rvm` gemset for instance, or
	specifying `GEM_PATH/cache` instead of `vendor/cache`._
* If you need the index available - needed when working in conjunction
    with [bundler-api](http://github.com/rubygems/bundler-api) - then run
    `bundle exec rake gemcutter:index:update`. This primes the filesystem gem index for
    local use.

#### Getting the test data

* A good way to get some test data is to import from a local gem directory.
`gem env` will tell you where rubygems stores your gems. Run
`bundle exec rake gemcutter:import:process #{INSTALLATION_DIRECTORY}/cache`

* If you see "Processing 0 gems" you’ve probably specified the wrong
directory. The proper directory will be full of .gem files.

#### Getting the data dumps
* You can use rubygems.org data [dumps](https://rubygems.org/pages/data) to test
application in development environment especially for performance related issues.

#### Pushing gems

* In order to push a gem to your local installation use a command like
    the following:

    ``` bash
    RUBYGEMS_HOST=http://localhost:3000 gem push hola-0.0.3.gem
    ```
---

When everything is set up, start the web server with `rails server` and browse to
[localhost:3000](http://localhost:3000) or use [Pow](http://pow.cx)!

Database Layout
---------------

Courtesy of [Rails ERD](http://voormedia.github.io/rails-erd/)

![Rubygems.org Domain Model](https://cdn.rawgit.com/rubygems/rubygems.org/master/doc/erd.svg)
