module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String?
        @name : String?

        getter id
        getter backend
        getter name

        setter backend
        setter name

        def initialize(@id : String)
        end

        def backend=(val : String | Symbol)
          @backend = val.to_s
        end

        def name=(val : Path | String | Symbol)
          @name = val.to_s
        end

        protected def validate
          raise_invalid_config("missing database backend") if backend.to_s.empty?

          unless DB::Connection::IMPLEMENTATIONS.has_key?(backend)
            raise_invalid_config("unknown database backend '#{backend}'")
          end

          raise_invalid_config("missing database name") if name.to_s.empty?
        end

        private def raise_invalid_config(msg)
          raise Errors::InvalidConfiguration.new("Invalid configuration for database '#{id}': #{msg}")
        end
      end
    end
  end
end
