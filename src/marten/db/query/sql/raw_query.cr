require "./query"

module Marten
  module DB
    module Query
      module SQL
        class RawQuery(Model)
          getter query
          getter params
          getter using

          setter using

          def initialize(@query : String, @params : Array(::DB::Any) | Hash(String, ::DB::Any), @using : String?)
          end

          def clone
            self.class.new(query: query, params: params, using: using)
          end

          def connection
            using.nil? ? Model.connection : Connection.get(using.not_nil!)
          end

          def execute : Array(Model)
            execute_query(*build_query)
          end

          private NAMED_PARAMETER_RE        = /(:?):([a-zA-Z]\w*)/
          private POSITIONAL_PARAMETER_CHAR = '?'
          private POSITIONAL_PARAMETER_RE   = /#{"\\" + POSITIONAL_PARAMETER_CHAR}/

          private def build_query
            sanitized_query, sanitized_params = case params
                                                when Array(::DB::Any)
                                                  sanitize_positional_parameters
                                                else
                                                  sanitize_named_parameters
                                                end

            {sanitized_query, sanitized_params}
          end

          private def execute_query(query, parameters)
            results = [] of Model

            connection.open do |db|
              db.query query, args: parameters do |result_set|
                result_set.each do
                  results << Model.from_db_row_iterator(RowIterator.new(Model, result_set, Array(Join).new))
                end
              end
            end

            results
          end

          private def sanitize_named_parameters
            sanitized_params = [] of ::DB::Any

            parameter_offset = 0
            sanitized_query = query.gsub(NAMED_PARAMETER_RE) do |match|
              # Specifically handle PostgreSQL's cast syntax (::).
              next match if $1 == ":"

              parameter_match = $2.to_s
              if !params.as(Hash).has_key?(parameter_match)
                raise Errors::UnmetQuerySetCondition.new("Missing parameter '#{parameter_match}' for query: #{query}")
              end

              parameter_offset += 1
              sanitized_params << params.as(Hash(String, ::DB::Any))[parameter_match]
              connection.parameter_id_for_ordered_argument(parameter_offset)
            end

            {sanitized_query, sanitized_params}
          end

          private def sanitize_positional_parameters
            if query.count(POSITIONAL_PARAMETER_CHAR) != params.size
              raise Errors::UnmetQuerySetCondition.new("Wrong number of parameters provided for query: #{@query}")
            end

            parameter_offset = 0
            sanitized_query = query.gsub(POSITIONAL_PARAMETER_RE) do
              parameter_offset += 1
              connection.parameter_id_for_ordered_argument(parameter_offset)
            end

            {sanitized_query, params.as(Array(::DB::Any))}
          end
        end
      end
    end
  end
end
