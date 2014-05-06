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

[mailing list]: http://groups.google.com/group/rubygems-org
[faq]: http://help.rubygems.org/kb/gemcutter/faq
[irc]: http://webchat.freenode.net/?channels=gemcutter
[travis]: http://travis-ci.org/rubygems/rubygems.org
[gemnasium]: https://gemnasium.com/rubygems/rubygems.org
[code climate]: https://codeclimate.com/github/rubygems/rubygems.org
[trello board]: https://trello.com/board/rubygems-org/513f9634a7ed906115000755

## TUF

The Update Framework (TUF) is used on top of the Rubygems file structure to
provide defence against a number of different attacks.

### Development

Bootstrap a TUF environment with default keys.

    export PATH=script/tuf:$PATH
    tuf-dev-bootstrap config/keys config/tuf

After running the server and `rake jobs:work`, upload a new gem:

    RUBYGEMS_HOST=http://localhost:3000 gem push yourgem-0.0.1.gem

That gem can now be fetched with TUF:

    script/fetch-me-a-gem-with-tuf yourgem

### Production

Production requires more setup because offline keys need to be distributed to
maintainers, who then need to sign for the initial metadata files.

    # Setting up an initial repository, with offline keys for xavier and tony.
    export PATH=script/tuf:$PATH
    export KEYDIR=config/keys
    export TUFDIR=config/tuf
    mkdir -p $KEYDIR
    mkdir -p $TUFDIR

    tuf-generate-key $KEYDIR online # $KEYDIR/online-*.pem
    tuf-generate-key $KEYDIR xavier # $KEYDIR/xavier-*.pem
    tuf-generate-key $KEYDIR tony   # $KEYDIR/tony-*.pem

    # Generate initial set of offline documents that need to be # signed.
    # Need to know all the public keys that will be used to sign documents in
    # advance. Adding new ones will require re-signing by all keys.
    tuf-generate-offline-files $TUFDIR \
      --offline $KEYDIR/xavier-public.pem \
      --offline $KEYDIR/tony-public.pem \
      --online $KEYDIR/online-public.pem

    # Each individual signs for the offline files using their private key.
    # Public key is also required as an identifier.
    tuf-sign-files $KEYDIR/xavier-{private,public}.pem $TUFDIR/*.txt
    tuf-sign-files $KEYDIR/tony-{private,public}.pem $TUFDIR/*.txt

    # Publish an empty TUF repository using the already signed offline files,
    # and an online key to sign new files that need to be generated..
    tuf-bootstrap $KEYDIR/online-{private,public}.pem $TUFDIR

    rm $TUFDIR/*.txt

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
