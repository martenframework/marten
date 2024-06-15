module Marten
  module DB
    module Query
      class Expression
        class Filter
          def q(**kwargs)
            Node.new(**kwargs)
          end

          def q(raw_predicate : String)
            raise_empty_raw_predicate if raw_predicate.empty?
            Node.new(raw_predicate: raw_predicate)
          end

          def q(raw_predicate : String, *args)
            q(raw_predicate, args.to_a)
          end

          def q(raw_predicate : String, **kwargs)
            q(raw_predicate, kwargs.to_h)
          end

          def q(raw_predicate : String, params : Array)
            raise_empty_raw_predicate if raw_predicate.empty?

            raw_params = [] of ::DB::Any
            raw_params += params

            Node.new(raw_predicate: raw_predicate, params: raw_params)
          end

          def q(raw_predicate : String, params : Hash | NamedTuple)
            raise_empty_raw_predicate if raw_predicate.empty?

            raw_params = {} of String => ::DB::Any
            params.each { |k, v| raw_params[k.to_s] = v }

            Node.new(raw_predicate: raw_predicate, params: raw_params)
          end

          private def raise_empty_raw_predicate
            raise Errors::UnmetQuerySetCondition.new("Raw predicates cannot be empty")
          end
        end
      end
    end
  end
end
