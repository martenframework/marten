module Marten
  module DB
    module Query
      class Expression
        class Filter
          def q(**kwargs)
            Node.new(**kwargs)
          end

          def q(query_string : String)
            raise Errors::UnmetQuerySetCondition.new("Query string cannot be empty") if query_string.empty?

            RawNode.new(query_string)
          end

          def q(query_string : String, *args)
            q(query_string, args.to_a)
          end

          def q(query_string : String, **kwargs)
            q(query_string, kwargs.to_h)
          end

          def q(query_string : String, params : Array)
            raw_params = [] of ::DB::Any
            raw_params += params

            RawNode.new(query_string, raw_params)
          end

          def q(query_string : String, params : Hash | NamedTuple)
            raw_params = {} of String => ::DB::Any
            params.each { |k, v| raw_params[k.to_s] = v }

            RawNode.new(query_string, raw_params)
          end
        end
      end
    end
  end
end
