module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String?
        @host : String?
        @name : String?
        @name_set_with_env : String?
        @password : String?
        @port : Int32?
        @target_env : String?
        @user : String?

        getter id
        getter backend
        getter host
        getter name
        getter password
        getter port
        getter user

        # :nodoc:
        getter name_set_with_env

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
          @name_set_with_env = @target_env
        end

        def password=(val : String | Symbol)
          @password = val.to_s
        end

        def port=(val : Int)
          @port = val.to_i32
        end

        def user=(val : String | Symbol)
          @user = val.to_s
        end

        # :nodoc:
        def validate : Nil
          raise_invalid_config("missing database backend") if backend.to_s.empty?

          unless DB::Connection::IMPLEMENTATIONS.has_key?(backend)
            raise_invalid_config("unknown database backend '#{backend}'")
          end

          raise_invalid_config("missing database name") if name.to_s.empty?
        end

        # :nodoc:
        def with_target_env(target_env : String?)
          current_target_env = @target_env
          @target_env = target_env
          yield self
        ensure
          @target_env = current_target_env
        end

        private def raise_invalid_config(msg)
          raise Errors::InvalidConfiguration.new("Invalid configuration for database '#{id}': #{msg}")
        end
      end
    end
  end
end
