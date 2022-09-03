module Marten
  module Template
    class Engine
      @context_producers = [] of ContextProducer
      @loaders = [] of Loader::Base

      getter context_producers
      getter loaders

      setter context_producers
      setter loaders

      # Returns the first compiled template matching the given template name.
      def get_template(template_name : String) : Template
        @loaders.each do |loader|
          begin
            return loader.get_template(template_name)
          rescue Errors::TemplateNotFound
          end
        end

        raise Errors::TemplateNotFound.new("Template #{template_name} could not be found")
      end
    end
  end
end
