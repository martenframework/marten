module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String | Symbol | Nil
        @name : Path | String | Symbol | Nil

        getter id
        getter backend
        getter name

        setter backend
        setter name

        def initialize(@id : String)
        end

        protected def validate
          raise Errors::InvalidConfiguration.new("A database backend must be chosen") if backend.nil?

          unless DB::Connection::IMPLEMENTATIONS.has_key?(backend.not_nil!.to_s)
            raise Errors::InvalidConfiguration.new("Unknown database backend: '#{backend}'")
          end
        end
      end
    end
  end
end
