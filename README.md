# Dry::Config

Simple base class for DRY environment based configurations that can be loaded from multiple overriding yml files.  

A programmatic seed configuration may be specified, as well as the ability to load multiple overriding configuration files 
(think multi-environment and a white label multi-domain configuration).
 
The [elastic-beanstalk gem](https://github.com/alienfast/elastic-beanstalk) is a real world example that utilized `Dry::Config::Base`.

## Installation

Add this line to your application's Gemfile:

    gem 'dry-config'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-config

## Usage

### Step 1.  Write a config class
Note this sample uses the `Singleton` pattern, which is useful but not required.

```ruby    
    require 'singleton'
    require 'dry/config'
    
    class AcmeConfig < Dry::Config::Base
        
        # (optional) make this the only instance 
        include Singleton
        
        # seed the sensible defaults here
        def seed_default_configuration
          
          @configuration = {
              environment: nil,
              strategy: :blue_green,
              package: {
                  verbose: false
              },
              options: {}
          }
        end
    end
```
    
### Step 2.  Write a yml config file
    
```yaml
    # sample config demonstrating multi-environment override
    ---
    app: acme
    title: Acme Holdings, LLC
    #---
    options:
      aws:elasticbeanstalk:application:environment:
        RAILS_ENV: foobar
    
      aws:autoscaling:launchconfiguration:
        InstanceType: foo
    
    #---
    development:
      strategy: inplace-update
      package:
        verbose: true
      options:
        aws:autoscaling:launchconfiguration:
          InstanceType: t1.micro
        aws:elasticbeanstalk:application:environment:
          RAILS_ENV: development
    
    #---
    production:
      options:
        aws:autoscaling:launchconfiguration:
          InstanceType: t1.large
        aws:elasticbeanstalk:application:environment:
          RAILS_ENV: production    
```

### Step 3. Load your config
 Note that multiple files can be loaded and overriden.  A nil environment is also possible.
 
```ruby
     AcmeConfig.instance.load!(:production, 'path_to/acme.yml')
```

### Step 4. Use the values
 Note that all keys are symbolized upon loading.

```ruby
    config = Acme.config.instance
    config.load!(:production, 'path_to/acme.yml')
    
    config.app          # acme
    config.title        # Acme Holdings, LLC    
    config.strategy     # :blue_green,
    config.options[:'aws:autoscaling:launchconfiguration'][:InstanceType] # t1.large
```   
   
## Other options
- Expected environments are `[:development, :test, :staging, :production]`.  Expand or redefine `@potential_environments` these by overriding the `#initialize` or doing so in your optional `#seed_default_configuration`.  This is used in the used in the overlay pruning process to prevent unused branches of configuration from showing up in the resolved configuration.
- An optional `#seed_default_configuration` allows you to provide a configuration base    
- `#clear` will restore to the seed configuration, allowing you to `#load!` new settings.
   
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
