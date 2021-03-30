module Marten
  module Template
    # Allows to configure a specific class as ussable within Marten templates (Crinja).
    module ContextObject
      macro setup_context_support
        include Crinja::Object::Auto

        @[Crinja::Attributes]
        class ::{{ @type }}
        end

        macro inherited
          setup_context_support
        end
      end

      macro included
        setup_context_support
      end
    end
  end
end
