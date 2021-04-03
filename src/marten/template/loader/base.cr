module Marten
  module Template
    module Loader
      abstract class Base
        # Returns the raw content of template from a specific template name.
        abstract def get_template_source(template_name) : String

        # Returns a `Marten::Template::Template` compiled template from a specific template name.
        def get_template(template_name) : Template
          Template.new(get_template_source(template_name))
        end
      end
    end
  end
end
