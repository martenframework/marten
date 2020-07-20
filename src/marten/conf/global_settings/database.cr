module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String?
        @host : String?
        @name : String?
        @password : String?
        @user : String?

        getter id
        getter backend
        getter host
        getter name
        getter password
        getter user

        def initialize(@id : String)
        end

        def backend=(val : String | Symbol)
          @backend = val.to_s
        end

        def host=(val : String | Symbol)
          @host = val.to_s
        end

        def name=(val : Path | String | Symbol)
          @name = val.to_s
        end

        def password=(val : String | Symbol)
          @password = val.to_s
        end

        def user=(val : String | Symbol)
          @user = val.to_s
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
