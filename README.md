# RubyGems.org (née Gemcutter)
The Ruby community's gem host.

## Purpose

* Provide a better API for dealing with gems
* Create more transparent and accessible project pages
* Enable the community to improve and enhance the site

## Links

* [Mailing List][]
* [FAQ][]
* [IRC][]: #rubygems on Freenode
* [Travis][]: [![Build Status](https://img.shields.io/travis/rubygems/rubygems.org/master.svg)][travis]
* [Gemnasium][]: [![Dependency Status](https://img.shields.io/gemnasium/rubygems/rubygems.org.svg)][gemnasium]
* [Code Climate][]: [![Code Climate](https://img.shields.io/codeclimate/github/rubygems/rubygems.org.svg)][code climate]
* [Trello Board][]

[mailing list]: https://groups.google.com/group/rubygems-org
[faq]: http://help.rubygems.org/kb/gemcutter/faq
[irc]: https://webchat.freenode.net/?channels=rubygems
[travis]: https://travis-ci.org/rubygems/rubygems.org
[gemnasium]: https://gemnasium.com/rubygems/rubygems.org
[code climate]: https://codeclimate.com/github/rubygems/rubygems.org
[trello board]: https://trello.com/board/rubygems-org/513f9634a7ed906115000755

## Contributions

Please follow our [contribution guidelines][].

[contribution guidelines]: https://github.com/rubygems/rubygems.org/blob/master/CONTRIBUTING.md

To get setup, please check out the [Development Setup][].

[development setup]: https://github.com/rubygems/rubygems.org/blob/master/CONTRIBUTING.md

Our deployment process is documented on the wiki as well, there's a multi-step
[Checklist][] to run through.

[checklist]: https://github.com/rubygems/rubygems.org/wiki/Deployment

Also please take note of our [Code of Conduct](https://github.com/rubygems/rubygems.org/blob/master/CONDUCT.md).

If you have any trouble or questions getting set up please create an issue on this repository and we'll be happy to help!

## Organization

RubyGems.org consists of a few major parts:

* Rails app: To manage users and allow others to view gems, etc.
* Sinatra app (Hostess): the gem server
* Gem processor: Handles incoming gems and storing them in S3 (production) or
  on the filesystem in `server/` (development).

## License

RubyGems.org uses the MIT license. Please check the [LICENSE][] file for more details.

[license]: https://github.com/rubygems/rubygems.org/blob/master/MIT-LICENSE
