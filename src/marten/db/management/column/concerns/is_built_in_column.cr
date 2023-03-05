module Marten
  module DB
    module Management
      module Column
        # :nodoc:
        module IsBuiltInColumn
          macro included
            def sql_quoted_default_value(connection : Connection::Base) : ::String?
              return if default.nil?
              SchemaEditor.for(connection).quoted_default_value_for_built_in_column(default)
            end

            def sql_type(connection : Connection::Base) : ::String
              SchemaEditor.for(connection).column_type_for_built_in_column(self) % db_type_parameters
            end

            def sql_type_suffix(connection : Connection::Base) : ::String?
              SchemaEditor.for(connection).column_type_suffix_for_built_in_column(self)
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
