module Marten
  module Routing
    module Rule
      abstract class Base
        abstract def name
        abstract def resolve(path : String) : Nil | Match
        protected abstract def reversers : Array(Reverser)

        private PARAMETER_RE      = /<(?P<name>\w+)(?::(?P<type>[^>:]+))?>/
        private PARAMETER_NAME_RE = /^[a-z_][a-zA-Z_0-9]*$/

        private def path_to_regex(path : String)
          processed_path = path.dup
          regex_parts = ["^"]
          path_for_interpolation = ""
          parameters = {} of String => Parameter::Base

          while processed_path.size > 0
            param_match = PARAMETER_RE.match(processed_path)
            if param_match.nil?
              regex_parts << processed_path
              path_for_interpolation += processed_path
              processed_path = ""
              next
            end

            regex_parts << processed_path[...param_match.begin]
            path_for_interpolation += processed_path[...param_match.begin]
            processed_path = processed_path[param_match.end..]
            parameter_name = param_match["name"]

            unless PARAMETER_NAME_RE.match(parameter_name)
              raise Errors::InvalidParameterName.new(
                %(Route "#{path}" contains parameter name "#{parameter_name}" which isn't a valid Crystal variable name)
              )
            end

            parameter_type = param_match["type"]? ? param_match["type"] : Parameter::DEFAULT_TYPE
            begin
              parameter_handler = Parameter.registry[parameter_type]
            rescue KeyError
              raise Errors::UnknownParameterType.new(
                %(Route "#{path}" contains parameter type "#{parameter_type}" which isn't a valid route parameter type)
              )
            end

            parameters[parameter_name] = parameter_handler
            regex_parts << "(?P<#{parameter_name}>#{parameter_handler.regex})"
            path_for_interpolation += "%{#{parameter_name}}"
          end

          {Regex.new(regex_parts.join("")), path_for_interpolation, parameters}
        end
      end
    end
  end
end
