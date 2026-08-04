module Marten
  module Template
    module Loader
      # A template loader that allows to persist compiled template in a memory cache.
      class Cached < Base
        def initialize(@loaders : Array(Loader::Base))
          @templates_cache = Hash(String, Template).new
          @mutex = Mutex.new
        end

        def get_template(template_name) : Template
          @mutex.synchronize do
            if template = @templates_cache[template_name]?
              return template
            end
          end

          template = nil

          @loaders.each do |loader|
            begin
              template = loader.get_template(template_name)
            rescue Errors::TemplateNotFound
              next
            end

            break unless template.nil?
          end

          if template.nil?
            raise Errors::TemplateNotFound.new("Template #{template_name} could not be found")
          end

          # Store under the lock; another fiber may have cached the same template meanwhile.
          @mutex.synchronize do
            @templates_cache[template_name] ||= template
          end
        end

        def get_template_source(template_name) : String
          raise NotImplementedError.new("The cached loader does not load template sources directly")
        end
      end
    end
  end
end
