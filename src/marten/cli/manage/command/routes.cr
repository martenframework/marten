module Marten
  module CLI
    class Manage
      module Command
        class Routes < Base
          help "Display all the routes of the application."

          def run
            process_routes_map(Marten.routes)
          end

          private def process_routes_map(map, parent_path = "", parent_name = nil)
            map.rules.each do |rule|
              case rule
              when Marten::Routing::Rule::Path
                print_path(rule, parent_path, parent_name)
              when Marten::Routing::Rule::Map
                rule_name = parent_name ? "#{parent_name}:#{rule.name}" : rule.name
                rule_path = parent_path + rule.path
                process_routes_map(rule.map, parent_path: rule_path, parent_name: rule_name)
              end
            end
          end

          private def print_path(rule, parent_path, parent_name)
            parts = [] of String
            empty_parent_name = parent_name.nil? || parent_name.empty?

            parts << style(parent_path + rule.path, fore: :light_blue)
            parts << style("[#{empty_parent_name ? rule.name : "#{parent_name}:#{rule.name}"}]", fore: :light_yellow)
            parts << "›"
            parts << style(rule.handler.name, fore: :light_green)

            if rule.handler.http_method_names != Handlers::Base.http_method_names
              parts << "(#{rule.handler.http_method_names.join(", ")})"
            end

            print(parts.join(" "))
          end
        end
      end
    end
  end
end
