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
* [Travis][]: [![Build Status](https://secure.travis-ci.org/rubygems/rubygems.org.png?branch=master)][travis]
* [Gemnasium][]: [![Dependency Status](https://gemnasium.com/rubygems/rubygems.org.png?travis)][gemnasium]
* [Code Climate][]: [![Code Climate](https://codeclimate.com/github/rubygems/rubygems.org.png)][code climate]
* [Trello Board][]

[mailing list]: http://groups.google.com/group/rubygems-org
[faq]: http://help.rubygems.org/kb/gemcutter/faq
[irc]: http://webchat.freenode.net/?channels=gemcutter
[travis]: http://travis-ci.org/rubygems/rubygems.org
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

## Organization

RubyGems.org consists of a few major parts:

* Rails app: To manage users and allow others to view gems, etc.
* Sinatra app (Hostess): the gem server
* Gem processor: Handles incoming gems and storing them in S3 (production) or
  on the filesystem in `server/` (development).

## License

RubyGems.org uses the MIT license. Please check the [LICENSE][] file for more details.

[license]: https://github.com/rubygems/rubygems.org/blob/master/MIT-LICENSE
