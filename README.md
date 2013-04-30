# motion-hockeyrink

motion-hockeyrink allows RubyMotion projects to easily embed the [HockeyApp SDK](http://hockeyapp.net/) and be submitted to HockeyApp

## Installation

`gem install motion-hockeyrink`

## Setup

In your Rakefile:

```ruby
require 'motion-cocoapods'

Motion::Project::App.setup do |app|
  # ...

  # Mandatory
  app.identifier = "com.usepropeller.hockeyapp.example"

  # Mandatory
  app.version = "0.0.1"

  # Mandatory
  app.pods do
    pod 'HockeySDK'
  end

  app.hockeyapp do
    # Mandatory
    app.hockeyapp.api_token = "your_api_token"
    # Mandatory
    app.hockeyapp.app_id = "your_app_id"

    # other options for app.hockeyapp; see "Configurations" below
  end
end
```

## Usage

```shell
$ rake hockeyapp
# ...
   Create ./build/iPhoneOS-6.1-Development/Example.dSYM
   Upload #<HockeyApp>
```

### Configuration

The `app.hockeyapp` and `rake hockeyapp` task accept the following options:

- `notes` - Release notes for this version
- `notes_type`, either `"textile"` or `"markdown"` - The format of your release notes (default is `"textile"`)
- `notify`, either `true` or `false` - Whether or not to notify your testers (default is `false`)
- `status`, either `"deny"` or `"allow"` - Whether testers can download the new version (default is `"deny"`)
- `mandatory`

So, this:

```ruby
app.hockeyapp.notes = "New version"
app.hockeyapp.notify = true
```

is the same as:

```
rake hockeyapp notes='New version' notify=true
```

## License

See [LICENSE](https://github.com/usepropeller/motion-hockeyrink/blob/master/LICENSE)
