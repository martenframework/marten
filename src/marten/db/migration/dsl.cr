module Marten
  module DB
    abstract class Migration
      module DSL
        macro add_column(table_name, *args, **kwargs)
          register_operation(
            Operation::AddColumn.new(
              {{ table_name }},
              _init_column({{ args.splat }}, {{ kwargs.double_splat }})
            )
          )
        end

        macro add_index(table_name, name, column_names)
          register_operation(
            Operation::AddIndex.new(
              {{ table_name }},
              _init_index({{ name }}, {{ column_names }})
            )
          )
        end

        macro add_unique_constraint(table_name, name, column_names)
          register_operation(
            Operation::AddUniqueConstraint.new(
              {{ table_name }},
              _init_unique_constraint({{ name }}, {{ column_names }})
            )
          )
        end

        macro change_column(table_name, *args, **kwargs)
          register_operation(
            Operation::ChangeColumn.new(
              {{ table_name }},
              _init_column({{ args.splat }}, {{ kwargs.double_splat }})
            )
          )
        end

        macro create_table(name)
          register_operation(
            CreateTable.new({{ name }}).build do
              {{ yield }}
            end.operation
          )
        end

        macro delete_table(name)
          register_operation(
            Operation::DeleteTable.new({{ name }})
          )
        end

        macro execute(forward_sql, backward_sql = nil)
          register_operation(
            Operation::ExecuteSQL.new({{ forward_sql }}, {{ backward_sql }})
          )
        end

        macro faked
          with_faked_operations_registration do
            {{ yield }}
          end
        end

        macro remove_column(table_name, column_name)
          register_operation(
            Operation::RemoveColumn.new({{ table_name }}, {{ column_name }})
          )
        end

        macro remove_index(table_name, index_name)
          register_operation(
            Operation::RemoveIndex.new({{ table_name }}, {{ index_name }})
          )
        end

        macro remove_unique_constraint(table_name, constraint_name)
          register_operation(
            Operation::RemoveUniqueConstraint.new({{ table_name }}, {{ constraint_name }})
          )
        end

        macro rename_column(table_name, old_name, new_name)
          register_operation(
            Operation::RenameColumn.new({{ table_name }}, {{ old_name }}, {{ new_name }})
          )
        end

        macro rename_table(old_name, new_name)
          register_operation(
            Operation::RenameTable.new({{ old_name }}, {{ new_name }})
          )
        end

        macro run_code(forward_method)
          register_operation(
            Operation::RunCode.new(->{ {{ forward_method.id }} })
          )
        end

        macro run_code(forward_method, backward_method)
          register_operation(
            Operation::RunCode.new(->{ {{ forward_method.id }} }, -> { {{ backward_method.id }} })
          )
        end

        # :nodoc:
        macro _init_column(*args, **kwargs)
          {% if args.size != 2 %}{% raise "A column name and type must be explicitly specified" %}{% end %}

          {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
          {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid column name" %}{% end %}

          {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
          {% if sanitized_type.is_a?(NilLiteral) %}
            {% raise "Cannot use '#{args[1]}' as a valid column type" %}
          {% end %}

          {% type_exists = false %}
          {% column_klass = nil %}
          {% for k in Marten::DB::Management::Column::Base.all_subclasses %}
            {% ann = k.annotation(Marten::DB::Management::Column::Registration) %}
            {% if ann && ann[:id] == sanitized_type %}
              {% type_exists = true %}
              {% column_klass = k %}
            {% end %}
          {% end %}
          {% unless type_exists %}
            {% raise "'#{sanitized_type}' is not a valid type for column '#{@type.id}##{sanitized_id}'" %}
          {% end %}

          {{ column_klass }}.new(
            {{ sanitized_id.stringify }},
            {% unless kwargs.is_a?(NilLiteral) || kwargs.empty? %}**{{ kwargs }}{% end %}
          )
        end

        # :nodoc:
        macro _init_index(name, column_names)
          Marten::DB::Management::Index.new({{ name }}, {{ column_names }})
        end

        # :nodoc:
        macro _init_unique_constraint(name, column_names)
          Marten::DB::Management::Constraint::Unique.new({{ name }}, {{ column_names }})
        end
      end
    end
  end
end
