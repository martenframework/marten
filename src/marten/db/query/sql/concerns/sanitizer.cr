module Marten
  module DB
    module Query
      module SQL
        module Sanitizer
          private NAMED_PARAMETER_RE        = /(:?):([a-zA-Z]\w*)/
          private POSITIONAL_PARAMETER_CHAR = '?'
          private POSITIONAL_PARAMETER_RE   = /#{"\\" + POSITIONAL_PARAMETER_CHAR}/

          # Prepares a raw SQL query with positional parameters for safe execution.
          # This function sanitizes a raw SQL query string that uses positional parameters (marked by `?`)
          # and constructs a new query string with placeholders that are compatible with the
          # database connection (if provided).
          # It also returns the sanitized parameters in a format suitable for passing to the database execution method.
          #
          # If the number of parameters provided does not match the number of placeholders in the query a
          # `Marten::DB::Errors::UnmetQuerySetCondition` error
          # will be raised.
          #
          # Example:
          # ```
          # query = "SELECT * FROM users WHERE id = ? AND name = ?"
          # params = [1, "Alice"]
          # sanitized_query, sanitized_params = sanitize_positional_parameters(query, params)
          # # => sanitized_query = "SELECT * FROM users WHERE id = $1 AND name = $2" (for PostgreSQL)
          # # => sanitized_params = [1, "Alice"]
          # ```
          def sanitize_positional_parameters(
            query : String,
            params : Array(::DB::Any),
            connection : Connection::Base? = nil
          )
            if query.count(POSITIONAL_PARAMETER_CHAR) != params.size
              raise Errors::UnmetQuerySetCondition.new("Wrong number of parameters provided for query: #{query}")
            end

            parameter_offset = 0
            sanitized_query = query.gsub(POSITIONAL_PARAMETER_RE) do
              # Conditional placeholder generation
              if connection
                parameter_offset += 1
                connection.parameter_id_for_ordered_argument(parameter_offset)
              else
                "%s"
              end
            end

            {sanitized_query, params}
          end

          # Prepares a raw SQL query with named parameters for safe execution.
          # This function sanitizes a raw SQL query string that uses named parameters (e.g., `:name`)
          # and constructs a new query string with placeholders that are compatible with the
          # database connection (if provided).
          # It also rearranges the parameters into an ordered array suitable for passing
          # to the database execution method.
          #
          # If the number of parameters provided does not match the number of placeholders in the query a
          # `Marten::DB::Errors::UnmetQuerySetCondition` error will be raised.
          #
          # Example:
          # ```
          # query = "SELECT * FROM users WHERE id = :id AND name = :name"
          # params = {"id" => 1, "name" => "Alice"}
          # sanitized_query, sanitized_params = sanitize_named_parameters(query, params)
          # # => sanitized_query = "SELECT * FROM users WHERE id = $1 AND name = $2" (for PostgreSQL)
          # # => sanitized_params = [1, "Alice"]
          # ```
          def sanitize_named_parameters(
            query : String,
            params : Hash(String, ::DB::Any),
            connection : Connection::Base? = nil
          )
            sanitized_params = [] of ::DB::Any

            parameter_offset = 0
            sanitized_query = query.gsub(NAMED_PARAMETER_RE) do |match|
              # Specifically handle PostgreSQL's cast syntax (::).
              next match if $1 == ":"

              parameter_match = $2.to_s
              if !params.has_key?(parameter_match)
                raise Errors::UnmetQuerySetCondition.new("Missing parameter '#{parameter_match}' for query: #{query}")
              end

              sanitized_params << params[parameter_match]

              # Conditional placeholder generation
              if connection
                parameter_offset += 1
                connection.parameter_id_for_ordered_argument(parameter_offset)
              else
                "%s"
              end
            end

            {sanitized_query, sanitized_params}
          end
        end
      end
    end
  end
end
