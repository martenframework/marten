require "./concerns/sanitizer"
require "./query"

module Marten
  module DB
    module Query
      module SQL
        class RawQuery(Model)
          include Sanitizer

          getter query
          getter params
          getter using

          setter using

          def initialize(@query : String, @params : Array(::DB::Any) | Hash(String, ::DB::Any), @using : String?)
          end

          def clone
            self.class.new(query: query, params: params, using: using)
          end

          # Returns the database connection to use for the raw query.
          #
          # By default the model's read connection is returned. Pass `write: true` when the raw SQL performs a mutation
          # so that database routers can resolve the write alias.
          def connection(*, write : Bool = false)
            using.nil? ? Model.connection(write: write) : Connection.get(using.not_nil!)
          end

          def execute : Array(Model)
            execute_query(*build_query)
          end

          private def build_query
            sanitized_query, sanitized_params = case params
                                                when Array(::DB::Any)
                                                  sanitize_positional_parameters(
                                                    query,
                                                    params.as(Array(::DB::Any)),
                                                    connection
                                                  )
                                                else
                                                  sanitize_named_parameters(
                                                    query,
                                                    params.as(Hash(String, ::DB::Any)),
                                                    connection
                                                  )
                                                end

            {sanitized_query, sanitized_params}
          end

          private def execute_query(query, parameters)
            results = [] of Model

            connection.open do |db|
              db.query query, args: parameters do |result_set|
                result_set.each do
                  results << Model.from_db_row_iterator(
                    RowIterator.new(
                      model: Model,
                      result_set: result_set,
                      joins: Array(Join).new,
                      annotations: Array(Annotation::Base).new,
                    ),
                    using
                  )
                end
              end
            end

            results
          end
        end
      end
    end
  end
end
