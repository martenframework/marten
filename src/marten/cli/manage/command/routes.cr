module Marten
  module CLI
    class Manage
      module Command
        class Routes < Base
          help "Display all the routes of the application."

          private getter! filter : String

          def setup
            on_option_with_arg(
              :g,
              :grep,
              :pattern,
              "Only display routes whose path or name contains the given substring (case-insensitive)"
            ) do |v|
              @filter = v
            end
          end

          def run
            printed = process_routes_map(Marten.routes)

            if filter? && printed.zero?
              print("No routes found matching #{filter.inspect}.")
            end
          end

          # Walks the routes map (recursing into nested and localized maps) and prints every matching route.
          # Returns the number of routes that were actually printed.
          private def process_routes_map(map, parent_path = "", parent_name = nil) : Int32
            printed = 0

            map.rules.each do |rule|
              case rule
              when Marten::Routing::Rule::Path
                printed += 1 if print_path(rule, parent_path, parent_name)
              when Marten::Routing::Rule::Map
                rule_name = parent_name ? "#{parent_name}:#{rule.name}" : rule.name
                rule_path = parent_path + resolve_path(rule.path)
                printed += process_routes_map(rule.map, parent_path: rule_path, parent_name: rule_name)
              when Marten::Routing::Rule::Localized
                rule.rules.each do |localized_rule|
                  case localized_rule
                  when Marten::Routing::Rule::Path
                    printed += 1 if print_path(localized_rule, "/<locale>", nil)
                  when Marten::Routing::Rule::Map
                    rule_name = parent_name ? "#{parent_name}:#{localized_rule.name}" : localized_rule.name
                    rule_path = "/<locale>" + parent_path + resolve_path(localized_rule.path)
                    printed += process_routes_map(localized_rule.map, parent_path: rule_path, parent_name: rule_name)
                  end
                end
              end
            end

            printed
          end

          # Prints the given route unless it is filtered out. Returns `true` when the route was printed.
          private def print_path(rule, parent_path, parent_name) : Bool
            empty_parent_name = parent_name.nil? || parent_name.empty?

            full_path = parent_path + resolve_path(rule.path)
            full_name = empty_parent_name ? rule.name : "#{parent_name}:#{rule.name}"

            return false unless matches_filter?(full_path, full_name)

            parts = [] of String
            parts << style(full_path, fore: :light_blue)
            parts << style("[#{full_name}]", fore: :light_yellow)
            parts << "›"
            parts << style(rule.handler.name, fore: :light_green)

            if rule.handler.http_method_names != Handlers::Base.http_method_names
              parts << "(#{rule.handler.http_method_names.join(", ")})"
            end

            print(parts.join(" "))

            true
          end

          private def matches_filter?(path : String, name : String) : Bool
            return true unless filter?

            pattern = filter.downcase
            path.downcase.includes?(pattern) || name.downcase.includes?(pattern)
          end

          private def resolve_path(path) : String
            case path
            when Routing::TranslatedPath
              I18n.t(path.key)
            else
              path.to_s
            end
          end
        end
      end
    end
  end
end
