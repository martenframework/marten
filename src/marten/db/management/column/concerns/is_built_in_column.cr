module Marten
  module DB
    module Management
      module Column
        # :nodoc:
        module IsBuiltInColumn
          macro included
            def sql_quoted_default_value(connection : Connection::Base) : ::String?
              return if default.nil?
              connection.schema_editor.quoted_default_value_for_built_in_column(default)
            end

            def sql_type(connection : Connection::Base) : ::String
              connection.schema_editor.column_type_for_built_in_column({{ @type.name.stringify }}) % db_type_parameters
            end

            def sql_type_suffix(connection : Connection::Base) : ::String?
              connection.schema_editor.column_type_suffix_for_built_in_column({{ @type.name.stringify }})
            end

            private def db_type_parameters
              nil
            end
          end
        end
      end
    end
  end
end
