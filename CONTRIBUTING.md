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

Also, if you’re hacking on Gemcutter, hop in `#rubygems` on
`irc.freenode.net`! Chances are someone else will be around to answer
questions or bounce ideas off of.

How To Contribute
-----------------

* Clone: `git clone git://github.com/rubygems/rubygems.org.git`
* Get [Setup](#setup)
* Create a topic branch: `git checkout -b awesome_feature`
* Commit away.
* Keep up to date: `git fetch && git rebase origin/master`.

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
[mailing list](http://groups.google.com/group/gemcutter) or IRC channel
(#gemcutter on irc.freenode.net) about them.

Acceptance
----------

**Contributions WILL NOT be accepted without tests.** If it’s a brand
new feature, you should have a [Cucumber](http://cukes.info) scenario
(or several!) as well. If you haven't tested before, start reading up
in the test/ directory to see what's going on. If you've got good links
regarding TDD or testing in general feel free to add them here!

Branching
---------

For your own development, use the topic branches. Basically, cut each
feature into its own branch and send pull requests based off those.

On the main repo, branches are used as follows:

<table>
    <thead>
        <tr>
            <th>Branch</th>
            <th>Used for...</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>`master`</td>
            <td>The main development branch. **Always** should be fast-forwardable.</td>
        </tr>
        <tr>
            <td>`staging`</td>
            <td>
                Whatever’s currently on http://staging.rubygems.org. Can be
                moved around as needed to test out new features/fixes. If
                you want to test out your changes on our staging server, bug
                qrush and you can play around there.
            </td>
        </tr>
        <tr>
            <td>`production`</td>
            <td>
                What’s currently on http://rubygems.org. Should be updated
                when deploys happen from master with `git push origin master:production`
            </td>
        </tr>
        <tr>
            <td>Topic branches</td>
            <td>
                Individual features/fixes. These should be moved around/rebased
                on top of the latest master before submitting. Makes your
                patches easier to merge and keep the history clean if at all
                possible.
            </td>
        </tr>
    </tbody>
</table>

## Development Setup

This page is for setting up Rubygems on a local development machine to
contribute patches/fixes/awesome stuff. **If you need to host your own
gem server, please consider checking out
[Geminabox](http://github.com/geminabox/geminabox). It’s a lot simpler
than Rubygems and may suit your organization’s needs better.**

### Setup

Some things you’ll need to do in order to get this project up and
running:

**Environment:**

* Use Ruby 1.9.3
* Install bundler: `gem install bundler`
* Install [redis](http://github.com/antirez/redis),
    **version 2.0 or higher**. If you have homebrew,
    do `brew install redis -H`, if you use macports,
    do `sudo port install redis`.
* Rubygems is configured to use PostgreSQL (>= 8.4.x),
    for MySQL see below. Install with: `brew install postgres`
* If this is your first time using pg, don't forget to initialize the database (initdb /usr/local/var/postgres -E utf8) before starting postgres (pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start)

**Get the code:**

* Clone the repo: `git clone git://github.com/rubygems/rubygems.org`
* Move into your cloned rubygems directory if you haven’t already: 
    `cd rubygems.org`
    
**Setup the database:**

* Get set up: `./script/setup`
* Run the database rake tasks if needed: 
    `rake db:create:all db:drop:all db:setup db:test:prepare --trace`

**Running tests:**

* Start redis: `redis-server`
* Run the tests: `rake`

**Developing on rubygems.org:**

* Set the REDISTOGO_URL environment variable. For example:
    `REDISTOGO_URL="redis://localhost:6379"`
* Import gems if you want to seed the database. 
    `rake gemcutter:import:process PATHTO_GEMS/cache`
    * _To import a small set of gems you can point the import process to any
        gems cache directory, like a very small `rvm` gemset for instance._
* If you need the index available - needed when working in conjunction
    with [bundler-api](http://github.com/rubygems/bundler-api) - then run
    `gemcutter:index:update`. This primes the filesystem gem index for
    local use.
* Start the web server: `rails server` and browse to
    [localhost:3000](http://localhost:3000) or use [Pow](http://pow.cx)!

**Pushing gems**

* In order to push a gem to your local installation use a command like
    the following:

    ``` bash
    RUBYGEMS_HOST=http://localhost:3000 gem push hola-0.0.3.gem
    ```

### MySQL

- Modify Gemfile to use `mysql` instead of `pg`
- If you’re running Max OS X Snow Leopard, the MySQL gem will fail to
    install without configuring it as follows:

    ``` bash
    bundle config build.mysql \
        —with-mysql-config=/usr/local/mysql/bin/mysql_config \
        export ARCHFLAGS=“-arch x86_64”
    ```

- Continue setup as above, installing dependencies, setting up
    database.yml, etc.

> **Warning:** Gem names are case sensitive (eg. `BlueCloth` vs.
> `bluecloth` 2). MySQL has a `utf8_bin` collation, but it appears
> that you still need to do `BINARY name = ?` for searching. 
> It is recommended that you stick to PostgreSQL >= 8.4.x 
> for development. Some tests will also fail if you use MySQL
> because some queries use SQL functions which don't exist in MySQL..

### MySQL2

* Remove `pg` gem from your Gemfile
* Add `mysql2` gem to your Gemfile:

     ``` ruby
       gem "mysql2"
     ```

* Run `bundle install` command

##### Working on the Gem

For testing/developing the gem, cd into the gem directory.
Please keep the code for the gem in there, don’t let it leak
out into the Rails app.

#### Getting some test data

A good way to get some test data is to import from a local gem directory.
`gem env` will tell you where rubygems stores your gems. Run
`rake gemcutter:import:process #{INSTALLATION_DIRECTORY}/cache`

If you see "Processing 0 gems" you’ve probably specified the wrong
directory. The proper directory will be full of .gem files.

#### Database Layout

Courtesy of [Rails ERD](http://rails-erd.rubyforge.org)

![Rubygems.org Domain Model](https://github.com/rubygems/rubygems.org/raw/master/doc/erd.png)
