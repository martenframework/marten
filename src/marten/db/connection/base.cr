module Marten
  module DB
    module Connection
      abstract class Base
        @db : ::DB::Database?
        @url : String
        @transactions = {} of UInt64 => ::DB::Transaction

        def initialize(@config : Conf::GlobalSettings::Database)
          @url = build_url
        end

        abstract def column_type_for_built_in_field(field_id)
        abstract def insert(
          table_name : String,
          values : Hash(String, ::DB::Any),
          pk_field_to_fetch : String? = nil
        ) : Int64?
        abstract def left_operand_for(id : String, predicate) : String
        abstract def operator_for(predicate) : String
        abstract def parameter_id_for_ordered_argument(number : Int) : String
        abstract def quote_char : Char
        abstract def sanitize_like_pattern(pattern : String) : String
        abstract def scheme : String

        def db
          @db ||= ::DB.open(@url)
        end

        def open(&block)
          yield current_transaction.nil? ? db : current_transaction.not_nil!.connection
        end

        def transaction
          current_transaction ? yield : new_transaction { yield }
        end

        def quote(name : String) : String
          "#{quote_char}#{name}#{quote_char}"
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

        private def build_url
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
      end
    end
  end
end
