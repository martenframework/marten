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
            DB::Connection.for(db_table)
          end

          # Allows to run the underlying block in a database transaction.
          #
          # A optional database alias can be specified in order to define the database connection to use in the context
          # of the transaction (otherwise it defaults to the default connection). If the passed database alias doesn't
          # correspond to any defined connections, a `Marten::DB::Errors::UnknownConnection` error will be raised.
          def transaction(using : Nil | String | Symbol = nil, &)
            conn = using.nil? ? connection : DB::Connection.get(using.to_s)
            conn.transaction do
              yield
            end
          end
        end

        # Allows to run the underlying block in a database transaction.
        #
        # A optional database alias can be specified in order to define the database connection to use in the context of
        # the transaction (otherwise it defaults to the default connection). If the passed database alias doesn't
        # correspond to any defined connections, a `Marten::DB::Errors::UnknownConnection` error will be raised.
        def transaction(using : Nil | String | Symbol = nil, &block)
          self.class.transaction(using, &block)
        end
      end
    end
  end
end
