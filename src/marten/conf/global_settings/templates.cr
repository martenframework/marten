module Marten
  module Conf
    class GlobalSettings
      # Allows to configure templates-related settings.
      class Templates
        @app_dirs : Bool = true
        @cached : Bool = false
        @context_producers = [] of Template::ContextProducer.class
        @dirs : Array(String) = [] of String

        # Returns a boolean indicating whether templates should be looked for inside installed applications.
        getter app_dirs

        # Returns a boolean indicating whether templates should be kept in a memory cache upon being loaded and parsed.
        getter cached

        # Returns an array of context producers that will be used to populate the context for each template.
        getter context_producers

        # Returns an array of directories where templates should be looked for.
        #
        # The order of these directories is important as it defines the order in which templates are searched for.
        getter dirs

        # Allows to set whether templates should be looked for inside installed applications.
        setter app_dirs

        # Allows to set whether templates should be kept in a memory cache upon being loaded and parsed.
        #
        # By default templates will be read from the filesystem and parsed every time they need to be rendered. When
        # setting this configuration option to `true`, compiled templates will be kept in memory and further renderings
        # of the same templates will result in previous compiled templates to be reused.
        setter cached

        # Allows to set the context producers that will be used to populate the context for each template.
        def context_producers=(v)
          @context_producers = Array(Template::ContextProducer.class).new
          @context_producers.concat(v)
        end

        # Allows to set the directories where templates should be looked for.
        def dirs=(dirs : Array(Path | String | Symbol))
          @dirs = dirs.map do |dir|
            case dir
            when Path
              dir.expand.to_s
            else
              dir.to_s
            end
          end
        end
      end
    end
  end
end
