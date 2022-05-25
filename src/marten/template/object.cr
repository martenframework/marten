require "./object/**"

module Marten
  module Template
    # Allows to add support for custom classes to template contexts.
    #
    # Including this module in a class will make it "compatible" with the template engine so that instances of this
    # class can be included in context objects.
    module Object
      # Allows to explicitly configure which methods are made available to the template engine.
      #
      # Only public mehtods that don't require arguments should be made available to templates.
      macro template_attributes(*names)
        # :nodoc:
        def resolve_template_attribute(key : ::String)
          case key
          {% for name in names %}
          when {% if name.is_a?(StringLiteral) %}{{ name }}{% else %}{{ name.id.stringify }}{% end %}
            {{ name.id }}
          {% end %}
          end
        end
      end
    end
  end
end
