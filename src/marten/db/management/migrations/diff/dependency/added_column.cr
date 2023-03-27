require "./base"

module Marten
  module DB
    module Management
      module Migrations
        class Diff
          module Dependency
            # Represents an added column dependency.
            #
            # This dependency can be used when a specific operation is dependent on a specific column being added first.
            class AddedColumn < Base
              getter app_label
              getter table_name
              getter column_name

              def initialize(@app_label : String, @table_name : String, @column_name : String)
              end

              def dependent?(operation : DB::Migration::Operation::Base) : Bool
                (
                  (
                    operation.is_a?(DB::Migration::Operation::CreateTable) &&
                      operation.name == table_name &&
                      operation.columns.any? { |c| c.name == column_name }
                  ) ||
                    (
                      operation.is_a?(DB::Migration::Operation::AddColumn) &&
                        operation.table_name == table_name &&
                        operation.column.name == column_name
                    )
                )
              end
            end
          end
        end
      end
    end
  end
end
