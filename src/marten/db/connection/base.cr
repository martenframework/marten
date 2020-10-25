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
        @transactions = {} of UInt64 => ::DB::Transaction

        def initialize(@config : Conf::GlobalSettings::Database)
          @url = build_url
        end

        # Allows to insert a new row in a specific table.
        abstract def insert(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_field_to_fetch : String? = nil
        ) : Int64?

        # Returns a `Marten::DB::Management::Introspector::Base` subclass instance to use to introspect the DB at hand.
        #
        # Each connection implementation should also implement a subclass of
        # `Marten::DB::Management::Introspector::Base`.
        abstract def introspector : Management::Introspector::Base

        # Returns the left operand to use for specific query predicate.
        #
        # Most of the time the initial ID will be left intact but depending on the connection implementation and the
        # considered predicate type (eg. "istartswith"), specific SQL functions could be applied on the column ID.
        abstract def left_operand_for(id : String, predicate) : String

        # Returns the operator to use for a specific query predicate.
        abstract def operator_for(predicate) : String

        # Returns the parameterized identifier for an ordered argument.
        #
        # This method takes the number of the argument which is aimed to be part of an array of ordered SQL arguments.
        abstract def parameter_id_for_ordered_argument(number : Int) : String

        # Returns the quote character to use to quote table names, columns, etc.
        abstract def quote_char : Char

        # Returns a `Marten::DB::Management::SchemaEditor::Base` subclass instance to edit the schema of the DB at hand.
        #
        # Each connection implementation should also implement a subclass of
        # `Marten::DB::Management::SchemaEditor::Base`.
        abstract def schema_editor : Management::SchemaEditor::Base

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
        def build_sql
          yield (clauses = [] of String?)
          clauses.compact!.join " "
        end

        # Returns a new database entrypoint to interact with the underlying database.
        def db
          @db ||= ::DB.open(@url)
        end

        # Provides a database entrypoint to the block.
        #
        # If this method is called in an existing transaction, the connection associated with this transaction will be
        # used instead.
        def open(&block)
          yield current_transaction.nil? ? db : current_transaction.not_nil!.connection
        end

        # Escapes special characters from a pattern aimed at being used in the context of a LIKE statement.
        def sanitize_like_pattern(pattern : String) : String
          pattern.gsub("%", "%").gsub("_", "_")
        end

        # Open a transaction.
        #
        # Atomicity will be ensured for the database operations performed inside the block. Note that any existing
        # transaction will be used in case of nested calls to this method.
        def transaction
          current_transaction ? yield : new_transaction { yield }
        end

        # Allows to quote a specific name (such as a table name or column ID) for the database at hand.
        def quote(name : String | Symbol) : String
          "#{quote_char}#{name}#{quote_char}"
        end

        # Returns true if the current database was explicitly configured for the test environment.
        #
        # The only way this method can return true is when the database name was explicitly set in a configuration
        # targetting the test environment.
        def test_database?
          @config.name_set_with_env == Conf::Env::TEST
        end

        protected def build_url
          parts = [] of String?

          parts << "#{scheme}://"

          unless @config.user.nil?
            parts << "#{@config.user}:#{@config.password}@"
          end

          if !@config.host.nil? && !@config.port.nil?
            parts << "#{@config.host}:#{@config.port}/"
          elsif !@config.host.nil?
            parts << "#{@config.host}/"
          end

          parts << @config.name

          parts.compact!.join("")
        end

        private getter transactions

        private def current_transaction
          transactions[Fiber.current.object_id]?
        end

        private def new_transaction
          db.transaction do |tx|
            transactions[Fiber.current.object_id] ||= tx
            yield
          end
          true
        rescue Marten::DB::Errors::Rollback
          false
        ensure
          transactions.delete(Fiber.current.object_id)
        end
      end
    end
  end
end
