require "./base"

module Marten
  module DB
    module Management
      module Migrations
        class Diff
          module Dependency
            # Represents a removed column dependency.
            #
            # This dependency can be used when a specific operation is dependent on a specific column being removed
            # first.
            class RemovedColumn < Base
              getter app_label
              getter table_name
              getter column_name

              def initialize(@app_label : String, @table_name : String, @column_name : String)
              end

              def dependent?(operation : DB::Migration::Operation::Base) : Bool
                operation.is_a?(DB::Migration::Operation::RemoveColumn) &&
                  operation.table_name == table_name &&
                  operation.column_name == column_name
              end
            end
          end
        end
      end
    end
  end
end
