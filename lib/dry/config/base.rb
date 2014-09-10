require 'dry/config/deep_symbolizable'
require 'yaml'

module Dry
  module Config
#
# Dry::Config::Base allows for default settings and mounting a specific environment with
# overriding hash values and merging of array values.
#
#   NOTE: Anything can be overridden and merged into top-level settings (hashes) including
#   anything that is an array value.  Array values are merged *not* replaced.  If you think
#   something is screwy, see the defaults in the #initialize as those add some default array values.
#   If this behavior of merging arrays or the defaults are somehow un-sensible, file an issue and we'll revisit it.
#
    class Base
      attr_reader :configuration

      def initialize
        seed_default_configuration

        # used for pruning initial base set.  See #load!
        @potential_environments = [:development, :test, :staging, :production]
      end

      def seed_default_configuration
        # override and seed the sensible defaults here
        @configuration = {}
      end

      # This is the main point of entry - we call #load! and provide
      # a name of the file to read as it's argument. We can also pass in some
      # options, but at the moment it's being used to allow per-environment
      # overrides in Rails
      def load!(environment, filename)

        # raise 'Unspecified environment' if environment.nil?
        raise 'Unspecified filename' if filename.nil?

        # save these in case we #reload
        @environment = environment
        @filename = filename

        # merge all top level settings with the defaults set in the #init

        deep_merge!(@configuration, YAML::load_file(filename).deep_symbolize)

        # add the environment to the top level settings
        @configuration[:environment] = (environment.nil? ? nil : environment.to_s)

        # TODO: the target file should be overlaid in an environment specific way in isolation, prior to merging with @configuration
        # TODO: otherwise this will kill prior wanted settings when merging multiple files.

        # overlay the specific environment if provided
        if environment && @configuration[environment.to_sym]

          # this is environment specific, so prune any environment
          # based settings from the initial set so that they can be overlaid.
          @potential_environments.each do |env|
            @configuration.delete(env)
          end

          # re-read the file
          environment_settings = YAML::load_file(filename).deep_symbolize

          # snag the requested environment
          environment_settings = environment_settings[environment.to_sym]

          # finally overlay what was provided
          #@configuration.deep_merge!(environment_settings)
          deep_merge!(@configuration, environment_settings)
        end
      end

      def reload!
        clear
        load! @environment, @filename
      end

      def clear
        seed_default_configuration
      end

      def method_missing(name, *args, &block)
        @configuration[name.to_sym] ||
            #fail(NoMethodError, "Unknown settings root \'#{name}\'", caller)
            nil
      end

      private

      def deep_merge!(target, data)
        merger = proc { |key, v1, v2|
          if (Hash === v1 && Hash === v2)
            v1.merge(v2, &merger)
          elsif (Array === v1 && Array === v2)
            v1.concat(v2)
          else
            v2
          end
        }
        target.merge! data, &merger
      end
    end
  end
end