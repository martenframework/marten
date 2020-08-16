module Marten
  module DB
    module Field
      # :nodoc:
      module IsBuiltInField
        macro included
          def db_type(connection : Connection::Base) : ::String
            connection.column_type_for_built_in_field({{ @type.name.stringify }}) % db_type_parameters
          end

          private def db_type_parameters
            nil
          end
        end
      end
    end
  end
end
