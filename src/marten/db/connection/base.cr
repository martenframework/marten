module Marten
  module DB
    module Connection
      # Abstract base class for a database connection.
      #
      # A database connection provides the main interface allowing to interact with the underlying database. Subclasses
      # must define a set of function allowing to define backend-specifics such as statements, operators, etc.
      abstract class Base
        @db : ::DB::Database?
        @url : String
        @transactions = {} of UInt64 => Transaction

        def initialize(@config : Conf::GlobalSettings::Database)
          @url = build_url
        end

        # Returns a distinct clause to remove duplicates from a query's results.
        #
        # If column names are specified, only these specific columns will be checked to identify duplicates.
        abstract def distinct_clause_for(columns : Array(String)) : String

        # Allows to insert a new row in a specific table.
        abstract def insert(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_field_to_fetch : String? = nil
        ) : ::DB::Any

        # Returns the left operand to use for specific query predicate.
        #
        # Most of the time the initial ID will be left intact but depending on the connection implementation and the
        # considered predicate type (eg. "istartswith"), specific SQL functions could be applied on the column ID.
        abstract def left_operand_for(id : String, predicate) : String

        # Returns a compatible value to use in the context of a LIMIT statement for the database at hand.
        abstract def limit_value(value : Int | Nil) : Int32 | Int64 | Nil | UInt32 | UInt64

        # Returns the maximum size for table names, column names or index / constraint names.
        abstract def max_name_size : Int32

        # Returns the operator to use for a specific query predicate.
        abstract def operator_for(predicate) : String

        # Returns the parameterized identifier for an ordered argument.
        #
        # This method takes the number of the argument which is aimed to be part of an array of ordered SQL arguments.
        abstract def parameter_id_for_ordered_argument(number : Int) : String

        # Returns the quote character to use to quote table names, columns, etc.
        abstract def quote_char : Char

        # Returns the scheme to consider for the underlying database backend.
        abstract def scheme : String

        # Allows to update an existing row in a specific table.
        abstract def update(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_column_name : String,
          pk_value : ::DB::Any
        ) : Nil

        # Returns the DB alias of the considered connection.
        def alias : String
          @config.id
        end

        # Allows to conveniently build a SQL statement by yielding an array of nillable strings.
        def build_sql(&)
          yield (clauses = [] of String?)
          clauses.compact!.join " "
        end

        # Returns the identifier of the connection.
        def id : String
          IMPLEMENTATIONS.key_for(self.class)
        end

        # Registers a proc to be called when the current transaction is committed to the databse.
        #
        # This method has no effect if it is called outside of a transaction block.
        def observe_transaction_commit(block : -> Nil)
          current_transaction.try(&.observe_commit(block))
        end

        # Registers a proc to be called when the current transaction is rolled back.
        #
        # This method has no effect if it is called outside of a transaction block.
        def observe_transaction_rollback(block : -> Nil)
          current_transaction.try(&.observe_rollback(block))
        end

        # Provides a database entrypoint to the block.
        #
        # If this method is called in an existing transaction, the connection associated with this transaction will be
        # used instead.
        def open(&)
          if (trx = current_transaction).nil?
            using_connection { |conn| yield conn }
          else
            yield trx.connection
          end
        end

        # Allows to quote a specific name (such as a table name or column ID) for the database at hand.
        def quote(name : String | Symbol) : String
          "#{quote_char}#{name}#{quote_char}"
        end

        # Escapes special characters from a pattern aimed at being used in the context of a LIKE statement.
        def sanitize_like_pattern(pattern : String) : String
          pattern.gsub("%", "\\%").gsub("_", "\\_")
        end

        # Open a transaction.
        #
        # Atomicity will be ensured for the database operations performed inside the block. Note that any existing
        # transaction will be used in case of nested calls to this method.
        def transaction(&)
          current_transaction ? yield : new_transaction { yield }
        end

        # Returns true if the current database was explicitly configured for the test environment.
        #
        # The only way this method can return true is when the database name was explicitly set in a configuration
        # targetting the test environment.
        def test_database?
          @config.name_set_with_env == Conf::Env::TEST
        end

        protected def build_url
          URI.new(
            scheme: scheme,
            user: @config.user,
            password: @config.password,
            host: @config.host,
            port: @config.port,
            path: @config.name || "",
            query: build_url_params
          ).to_s
        end

        protected def build_url_params
          URI::Params.build do |params|
            params.add("checkout_timeout", @config.checkout_timeout.to_s)
            params.add("initial_pool_size", @config.initial_pool_size.to_s)
            params.add("max_idle_pool_size", @config.max_idle_pool_size.to_s)
            params.add("max_pool_size", @config.max_pool_size.to_s)
            params.add("retry_attempts", @config.retry_attempts.to_s)
            params.add("retry_delay", @config.retry_delay.to_s)

            @config.options.each { |k, v| params.add(k, v) }
          end
        end

        protected def db
          @db ||= ::DB.open(@url)
        end

        private getter transactions

        private def current_transaction
          transactions[Fiber.current.object_id]?
        end

        private def mark_current_transaction_as_rolled_back
          current_transaction.try(&.rolled_back=(true))
        end

        private def new_transaction(&)
          using_connection do |conn|
            conn.transaction do |tx|
              transactions[Fiber.current.object_id] ||= Transaction.new(tx)
              yield
            end
          end
          true
        rescue Marten::DB::Errors::Rollback
          mark_current_transaction_as_rolled_back
          false
        rescue ex
          mark_current_transaction_as_rolled_back
          raise ex
        ensure
          release_current_transaction
        end

        private def release_current_transaction
          current_transaction.try(&.notify_observers)
          transactions.delete(Fiber.current.object_id)
        end

        private def using_connection(&)
          db.retry do
            db.using_connection do |conn|
              yield conn
            end
          end
        end
      end
    end
  end
end
