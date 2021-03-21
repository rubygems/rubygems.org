# RubyGems.org (née Gemcutter)
The Ruby community's gem host.

## Purpose

* Provide a better API for dealing with gems
* Create more transparent and accessible project pages
* Enable the community to improve and enhance the site

## Support

<a href="https://rubytogether.org/"><img src="https://rubytogether.org/images/rubies.svg" width=200></a>
<a href="https://rubycentral.org/"><img src="doc/ruby_central_logo.png" height=110></a><br/>

[RubyGems.org](https://rubygems.org) is managed by [Ruby Central](https://rubycentral.org), a community-funded organization supported by conference participation for [RailsConf](https://railsconf.org) and [RubyConf](https://rubyconf.org) through tickets and sponsorships.

Hosting fees are paid by Ruby Central and CDN fees are generously donated by [Fastly](https://fastly.com).

Additionally, [RubyTogether](https://rubytogether.org) sponsors individuals to work on development and operations work for RubyGems.org which augments volunteer efforts from the Ruby community.

[Learn more about our sponsors and how they work together.](https://rubygems.org/pages/sponsors)

## Links

* [Mailing List][]
* [FAQ][]
* [IRC][]: #rubygems on Freenode
* [GitHub Workflow][]: [![test workflow](https://github.com/rubygems/rubygems.org/actions/workflows/test.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/test.yml)
* [GitHub Workflow][]: [![lint workflow](https://github.com/rubygems/rubygems.org/actions/workflows/lint.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/lint.yml)
* [GitHub Workflow][]: [![docker workflow](https://github.com/rubygems/rubygems.org/actions/workflows/docker.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/docker.yml)
* [Code Climate][]: [![Maintainability](https://api.codeclimate.com/v1/badges/7110bb3f9b765042d604/maintainability)](https://codeclimate.com/github/rubygems/rubygems.org/maintainability)
* [Code Climate][]: [![Test Coverage](https://api.codeclimate.com/v1/badges/7110bb3f9b765042d604/test_coverage)](https://codeclimate.com/github/rubygems/rubygems.org/test_coverage)
* [Trello Board][]

[mailing list]: https://groups.google.com/group/rubygems-org
[faq]: https://help.rubygems.org/kb/gemcutter/faq
[irc]: https://webchat.freenode.net/?channels=rubygems
[github workflow]: https://github.com/rubygems/rubygems.org/actions/
[code climate]: https://codeclimate.com/github/rubygems/rubygems.org
[trello board]: https://trello.com/board/rubygems-org/513f9634a7ed906115000755

## Contributions

Please follow our [contribution guidelines][].

[contribution guidelines]: https://github.com/rubygems/rubygems.org/blob/master/CONTRIBUTING.md

To get setup, please check out the [Development Setup][].

[development setup]: https://github.com/rubygems/rubygems.org/blob/master/CONTRIBUTING.md#development-setup

Our deployment process is documented on the wiki as well, there's a multi-step
[Checklist][] to run through.

[checklist]: https://github.com/rubygems/rubygems-infrastructure/wiki/Deploys

Also please take note of our [Code of Conduct](https://github.com/rubygems/rubygems.org/blob/master/CODE_OF_CONDUCT.md).

If you have any trouble or questions getting set up please create an issue on this repository and we'll be happy to help!

## Organization

RubyGems.org consists of a few major parts:

* Rails app: To manage users and allow others to view gems, etc.
* Gem processor: Handles incoming gems and storing them in Amazon S3 (production) or
  on the filesystem in `server/` (development).

## License

RubyGems.org uses the MIT license. Please check the [LICENSE][] file for more details.

[license]: https://github.com/rubygems/rubygems.org/blob/master/MIT-LICENSE
