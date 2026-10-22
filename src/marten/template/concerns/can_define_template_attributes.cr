module Marten
  module Template
    module CanDefineTemplateAttributes
      # :nodoc:
      # Wrap attribute values before Crystal combines return types from different objects.
      def resolve_template_value(key : String) : Value
        Value.from(resolve_template_attribute(key))
      end

      # Allows to explicitly configure which methods are made available to the template engine.
      #
      # Only public methods that don't require arguments should be made available to templates.
      macro template_attributes(*names)
        # :nodoc:
        def resolve_template_attribute(key : ::String)
          case key
          {% for name in names %}
          when {% if name.is_a?(StringLiteral) %}{{ name }}{% else %}{{ name.id.stringify }}{% end %}
            {{ name.id }}
          {% end %}
          else
            raise Marten::Template::Errors::UnknownVariable.new
          end
        end
      end
    end
  end
end
