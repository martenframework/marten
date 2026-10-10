module Marten
  module DB
    abstract class Model
      module Connection
        macro included
          extend Marten::DB::Model::Connection::ClassMethods
        end

        module ClassMethods
          # Returns the database connection to use for the considered model.
          #
          # By default the connection is resolved by consulting the configured database routers. The optional `write`
          # argument can be set to `true` in order to resolve the connection for write operations instead of reads.
          def connection(*, write : Bool = false)
            DB::Connection.for(self, write: write)
          end

          # Allows to run the underlying block in a database transaction.
          #
          # A optional database alias can be specified in order to define the database connection to use in the context
          # of the transaction (otherwise the write connection for the model is used). If the passed database alias
          # doesn't correspond to any defined connections, a `Marten::DB::Errors::UnknownConnection` error will be
          # raised.
          def transaction(using : Nil | String | Symbol = nil, &)
            conn = using.nil? ? connection(write: true) : DB::Connection.get(using.to_s)
            conn.transaction do
              yield
            end
          end
        end

        # Returns the sticky database alias associated with the model instance, if any.
        #
        # The sticky alias is set when a record is loaded from or persisted to a specific database via an explicit
        # `#using` selection. Subsequent operations on the instance reuse this alias unless another one is specified
        # explicitly.
        getter using : String?

        # :nodoc:
        setter using

        # Allows to run the underlying block in a database transaction.
        #
        # A optional database alias can be specified in order to define the database connection to use in the context of
        # the transaction (otherwise the sticky alias of the instance or the model's write connection is used). If the
        # passed database alias doesn't correspond to any defined connections, a `Marten::DB::Errors::UnknownConnection`
        # error will be raised.
        def transaction(using : Nil | String | Symbol = nil, &block)
          self.class.transaction(using: using.nil? ? @using : using, &block)
        end

        # :nodoc:
        def ensure_relation_allowed(related_object : Model) : Nil
          return if Router.allow_relation?(self, related_object)

          raise Errors::InvalidRelation.new(
            "Relation between #{self.class.name} and #{related_object.class.name} is not allowed by database routers"
          )
        end

        protected def resolve_connection(using : Nil | String | Symbol = nil, *, write : Bool = false)
          if !using.nil?
            DB::Connection.get(using.to_s)
          elsif !(sticky = @using).nil?
            DB::Connection.get(sticky)
          else
            DB::Connection.for(self.class, write: write, instance: self)
          end
        end
      end
    end
  end
end
