module Marten
  module DB
    abstract class Model
      module Inheritance
        macro included
          extend Marten::DB::Model::Inheritance::ClassMethods
        end

        module ClassMethods
          # Returns `true` for an abstract model.
          def abstract?
            {% begin %}
              {% if @type.abstract? %}
                true
              {% else %}
                false
              {% end %}
            {% end %}
          end
        end
      end
    end
  end
end
