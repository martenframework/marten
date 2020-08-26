module Marten
  module DB
    abstract class Model
      module Connection
        macro included
          extend Marten::DB::Model::Connection::ClassMethods
        end

        module ClassMethods
          # Returns the database connection to use for the considered model.
          def connection
            DB::Connection.for(table_name)
          end

          # Allows to run the underlying block in a database transaction.
          def transaction(using : Nil | String | Symbol = nil)
            conn = using.nil? ? connection : DB::Connection.get(using.to_s)
            conn.transaction do
              yield
            end
          end
        end
      end
    end
  end
end
