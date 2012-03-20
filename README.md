# Haitatsu

Push style deployment, for those times you can't use Heroku.

## Installation

    $ gem install haitatsu

## Usage

Add a .haitatsu file to your project.

Here is a sample configuration.

    app: haitatsu
    user: haitatsu

    repo: haitatsu
    remote: haitatsu@example.com

    location: /srv/haitatsu

    servers:
      application-server:
        host: example.com
        tasks:
          - "bundle exec whenever --update-crontab"


Then run haitatsu to deploy your application.

    $ haitatsu

You can also make the deployment verbose.

    $ haitatsu -V

As well as force the deploy even if the version deployed is current.

    $ haitatsu -f

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
