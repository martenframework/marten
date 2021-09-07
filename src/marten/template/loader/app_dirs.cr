require "./base"
require "./file_system"

module Marten
  module Template
    module Loader
      # Represents a template loader allowing to load templates from the installed application directories.
      class AppDirs < Base
        @app_loaders : Array(Loader::FileSystem)

        def initialize
          @app_loaders = [] of Loader::FileSystem
          @app_loaders += Marten.apps.app_configs.compact_map(&.templates_loader)
        end

        def get_template(template_name) : Template
          app_loaders.each do |loader|
            return loader.get_template(template_name)
          rescue Errors::TemplateNotFound
          end

          raise Errors::TemplateNotFound.new("Template #{template_name} could not be found")
        end

        def get_template_source(template_name) : String
          raise NotImplementedError.new("The app dirs loader does not load template sources directly")
        end

        private getter app_loaders
      end
    end
  end
end
