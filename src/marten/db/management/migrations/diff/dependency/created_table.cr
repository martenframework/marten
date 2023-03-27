require "./base"

module Marten
  module DB
    module Management
      module Migrations
        class Diff
          module Dependency
            # Represents a created table dependency.
            #
            # This dependency can be used when a specific operation is dependent on a specific table being created
            # first.
            class CreatedTable < Base
              getter app_label
              getter table_name

              def initialize(@app_label : String, @table_name : String)
              end

              def dependent?(operation : DB::Migration::Operation::Base) : Bool
                operation.is_a?(DB::Migration::Operation::CreateTable) && operation.name == table_name
              end
            end
          end
        end
      end
    end
  end
end
