module Marten
  module Conf
    class GlobalSettings
      # Defines the configuration of a specific database connection.
      class Database
        @backend : String?
        @checkout_timeout : Float64 = 5.0
        @host : String?
        @initial_pool_size : Int32 = 1
        @max_idle_pool_size : Int32 = 1
        @max_pool_size : Int32 = 0 # unlimited
        @name : String?
        @name_set_with_env : String?
        @options = {} of String => String
        @password : String?
        @port : Int32?
        @retry_attempts : Int32 = 1
        @retry_delay : Float64 = 1.0
        @target_env : String?
        @user : String?

        # Returns the identifier of the database.
        getter id

        # Returns the connection backend of the database.
        getter backend

        # Returns the number of seconds to wait for a connection to become available when the max pool size is reached.
        getter checkout_timeout

        # Returns the database host.
        getter host

        # Returns the initial number of connections created for the database connections pool.
        getter initial_pool_size

        # Returns the maximum number of idle connections for the database connections pool.
        #
        # When released, a connection will be closed only if there are already `max_idle_pool_size` idle connections.
        getter max_idle_pool_size

        # Returns the maximum number of connections that will be held by the database connections pool.
        #
        # When set to `0`, this means that there is no limit to the number of connections.
        getter max_pool_size

        # Returns the database name.
        getter name

        # Returns the database options.
        getter options

        # Returns the database password.
        getter password

        # Returns the database port.
        getter port

        # Returns the maximum number of attempts to retry re-establishing a lost connection.
        getter retry_attempts

        # Returns the delay to wait between each retry at re-establishing a lost connection.
        getter retry_delay

        # Returns the database user name.
        getter user

        # :nodoc:
        getter name_set_with_env

        # Allows to set the seconds to wait for a connection to become available when the max pool size is reached.
        setter checkout_timeout

        # Allows to set the initial number of connections created for the database connections pool.
        setter initial_pool_size

        # Allows to set the maximum number of idle connections for the database connections pool.
        setter max_idle_pool_size

        # Allows to set the maximum number of connections that will be held by the database connections pool.
        setter max_pool_size

        # Allows to set additional database options.
        setter options

        # Allows to set the maximum number of attempts to retry re-establishing a lost connection.
        setter retry_attempts

        # Allows to set the delay to wait between each retry at re-establishing a lost connection.
        setter retry_delay

        def initialize(@id : String)
        end

        # Allows to set the connection backend of the database.
        def backend=(val : Nil | String | Symbol)
          @backend = val.try(&.to_s)
        end

        # Allows to set the database host.
        def host=(val : Nil | String | Symbol)
          @host = val.try(&.to_s)
        end

        # Allows to set the database name.
        def name=(val : Nil | Path | String | Symbol)
          @name = val.try(&.to_s)
          @name_set_with_env = @target_env
        end

        # Allows to set the database password.
        def password=(val : Nil | String | Symbol)
          @password = val.try(&.to_s)
        end

        # Allows to set the database port.
        def port=(val : Int | Nil)
          @port = val.try(&.to_i32)
        end

        # Allows to set the database user name.
        def user=(val : Nil | String | Symbol)
          @user = val.try(&.to_s)
        end

        # :nodoc:
        def validate : Nil
          raise_invalid_config("missing database backend") if backend.to_s.empty?

          unless DB::Connection::IMPLEMENTATIONS.has_key?(backend)
            raise_invalid_config("unknown database backend '#{backend}'")
          end

          unless driver_installed?
            raise_invalid_config(
              "database driver is not installed (please add '#{driver_shard_name}' to your shard.yml file)"
            )
          end

          raise_invalid_config("missing database name") if name.to_s.empty?
        end

        # :nodoc:
        def with_target_env(target_env : String?, &)
          current_target_env = @target_env
          @target_env = target_env
          yield self
        ensure
          @target_env = current_target_env
        end

        private def driver_installed?
          case backend
          when DB::Connection::MYSQL_ID
            mysql_database_driver_installed?
          when DB::Connection::POSTGRESQL_ID
            postgresql_database_driver_installed?
          when DB::Connection::SQLITE_ID
            sqlite3_database_driver_installed?
          end
        end

        private def driver_shard_name
          case backend
          when DB::Connection::MYSQL_ID
            "crystal-lang/crystal-mysql"
          when DB::Connection::POSTGRESQL_ID
            "will/crystal-pg"
          when DB::Connection::SQLITE_ID
            "crystal-lang/crystal-sqlite3"
          end
        end

        private def mysql_database_driver_installed?
          __marten_defined?(::MySql) do
            return true
          end

          false
        end

        private def postgresql_database_driver_installed?
          __marten_defined?(::PG) do
            return true
          end

          false
        end

        private def raise_invalid_config(msg)
          raise Errors::InvalidConfiguration.new("Invalid configuration for database '#{id}': #{msg}")
        end

        private def sqlite3_database_driver_installed?
          __marten_defined?(::SQLite3) do
            return true
          end

          false
        end
      end
    end
  end
end
