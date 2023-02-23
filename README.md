# RubyGems.org (née Gemcutter)
The Ruby community's gem host.

## Purpose

* Provide a better API for dealing with gems
* Create more transparent and accessible project pages
* Enable the community to improve and enhance the site

## Support

<a href="https://rubycentral.org/"><img src="doc/ruby_central_logo.png" height=110></a><br/>

[RubyGems.org](https://rubygems.org) is managed by [Ruby Central](https://rubycentral.org), a non-profit organization that supports the Ruby community through projects like this one, as well as [RubyConf](https://rubyconf.org), [RailsConf](https://railsconf.org), and [Bundler](https://bundler.io). You can support Ruby Central by attending or [sponsoring](sponsors@rubycentral.org) a conference, or by [joining as a supporting member](https://rubycentral.org/#/portal/signup).

Hosting is donated by [Amazon Web Services](https://aws.amazon.com), with CDN service donated by [Fastly](https://fastly.com).

[Learn more about our sponsors and how they work together.](https://rubygems.org/pages/sponsors)

## Links

* [Slack](https://bundler.slack.com/)
* [RFCs](https://github.com/rubygems/rfcs)
* [Support](mailto:support@rubygems.org)
* [GitHub Workflow][]: [![test workflow](https://github.com/rubygems/rubygems.org/actions/workflows/test.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/test.yml) [![lint workflow](https://github.com/rubygems/rubygems.org/actions/workflows/lint.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/lint.yml) [![docker workflow](https://github.com/rubygems/rubygems.org/actions/workflows/docker.yml/badge.svg)](https://github.com/rubygems/rubygems.org/actions/workflows/docker.yml)

[github workflow]: https://github.com/rubygems/rubygems.org/actions/

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
