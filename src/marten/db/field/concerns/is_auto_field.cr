module Marten
  module DB
    module Field
      # :nodoc:
      module IsAutoField
        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:primary_key].is_a?(NilLiteral) || !kwargs[:primary_key] %}
            {% raise "Auto fields fields must define 'primary_key: true'" %}
          {% end %}
        end

        protected def perform_validation(_record : Model); end
      end
    end
  end
end
