module Marten
  module DB
    module Query
      module SQL
        module Sanitizer
          private NAMED_PARAMETER_RE        = /(:?):([a-zA-Z]\w*)/
          private POSITIONAL_PARAMETER_CHAR = '?'
          private POSITIONAL_PARAMETER_RE   = /#{"\\" + POSITIONAL_PARAMETER_CHAR}/

          private def sanitize_positional_parameters(
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

          private def sanitize_named_parameters(
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
