module Marten
  module DB
    module Connection
      abstract class Base
        @db : ::DB::Database?
        @url : String

        def initialize(@config : Conf::GlobalSettings::Database)
          @url = build_url
        end

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
          yield db
        end

        def quote(name : String) : String
          "#{quote_char}#{name}#{quote_char}"
        end

        private def build_url
          parts = [] of String?

          parts << "#{scheme}://"

          unless @config.user.nil?
            parts << "#{@config.user}:#{@config.password}@"
          end

          unless @config.host.nil?
            parts << "#{@config.host}/"
          end

          parts << db_name

          parts.compact!.join("")
        end

        private def db_name
          @config.name
        end
      end
    end
  end
end
