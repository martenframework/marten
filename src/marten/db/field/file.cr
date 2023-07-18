module Marten
  module DB
    module Field
      # Represents a file field.
      class File < Base
        # :nodoc:
        alias AdditionalType = ::File | HTTP::UploadedFile

        getter default

        # Returns the max size of the string corresponding to the file path to be stored in the database.
        getter max_size

        # Returns the path where the file should be stored or a proc returning this path.
        getter upload_to

        def initialize(
          @id : ::String,
          @storage : Core::Storage::Base? = nil,
          @max_size : ::Int32 = 100,
          @default : ::String? = nil,
          @upload_to : Proc(::String, ::String) | ::String = "",
          @blank = false,
          @null = false,
          @unique = false,
          @index = false,
          @db_column = nil
        )
          @primary_key = false
        end

        def empty_value?(value) : ::Bool
          case value
          when Nil
            true
          when Marten::DB::Field::File::File
            !value.attached?
          when ::String
            value.empty?
          when Symbol
            value.to_s.empty?
          else
            raise_unexpected_field_value(value)
          end
        end

        def from_db(value) : Marten::DB::Field::File::File?
          value = case value
                  when Nil | ::String
                    value.as?(Nil | ::String)
                  else
                    raise_unexpected_field_value(value)
                  end

          return if value.nil?

          Marten::DB::Field::File::File.new(field: self, name: value)
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Marten::DB::Field::File::File?
          from_db(result_set.read(::String?))
        end

        def prepare_save(record, new_record = false)
          file = record.get_field_value(id).as?(Marten::DB::Field::File::File)

          if !file.nil? && !file.committed?
            case f = file.file
            when ::File
              file.save(file.name.not_nil!, f)
            when HTTP::UploadedFile
              file.save(file.name.not_nil!, f.io)
            end
          end
        end

        def sanitize_filename(filename : ::String) : ::String
          filename = if upload_to.is_a?(Proc)
                       upload_to.as(Proc).call(filename)
                     else
                       ::File.join(upload_to.as(::String), filename)
                     end

          validate_filename(filename)
        end

        # Returns the storage object that should be used to store the file.
        def storage
          @storage || Marten.media_files_storage
        end

        def to_column : Management::Column::Base?
          Management::Column::String.new(
            name: db_column!,
            max_size: max_size,
            primary_key: false,
            null: null?,
            unique: unique?,
            index: index?,
            default: to_db(default)
          )
        end

        def to_db(value) : ::DB::Any
          case value
          when Nil
            nil
          when Marten::DB::Field::File::File
            value.name
          when ::String
            value
          when Symbol
            value.to_s
          else
            raise_unexpected_field_value(value)
          end
        end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
          # Registers the field to the model class.

          class ::{{ model_klass }}
            register_field(
              {{ @type }}.new(
                {{ field_id.stringify }},
                {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
              )
            )

            {% if !model_klass.resolve.abstract? %}
              @[Marten::DB::Model::Table::FieldInstanceVariable(
                field_klass: {{ @type }},
                field_kwargs: {% unless kwargs.is_a?(NilLiteral) %}{{ kwargs }}{% else %}nil{% end %},
                field_type: ::File | Marten::DB::Field::File::File | Marten::HTTP::UploadedFile | Nil
              )]

              @{{ field_id }} : {{ field_ann[:exposed_type] }}?

              def {{ field_id }} : {{ field_ann[:exposed_type] }}?
                _{{ field_id }}_file
              end

              def {{ field_id }}!
                _{{ field_id }}_file
              end

              def {{ field_id }}?
                self.class.get_field({{ field_id.stringify }}).getter_value?({{ field_id }})
              end

              def {{ field_id }}=(@{{ field_id }} : {{ field_ann[:exposed_type] }}?); end

              def {{ field_id }}=(file : ::File)
                @{{ field_id }} = Marten::DB::Field::File::File.new(
                  field: self.class.get_field({{ field_id.stringify }}).as(Marten::DB::Field::File),
                  name: Path[file.path].basename
                )

                {{ field_id }}!.committed = false
                {{ field_id }}!.file = file

                {{ field_id }}!
              end

              def {{ field_id }}=(file : Marten::HTTP::UploadedFile)
                @{{ field_id }} = Marten::DB::Field::File::File.new(
                  field: self.class.get_field({{ field_id.stringify }}).as(Marten::DB::Field::File),
                  name: file.filename
                )

                {{ field_id }}!.committed = false
                {{ field_id }}!.file = file

                {{ field_id }}!
              end

              private def _{{ field_id }}_file
                @{{ field_id }} ||= Marten::DB::Field::File::File.new(
                  field: self.class.get_field({{ field_id.stringify }}).as(Marten::DB::Field::File)
                )
                @{{ field_id }}.not_nil!.record ||= self
                @{{ field_id }}.not_nil!
              end
            {% end %}
          end
        end

        private INVALID_FILENAMES = ["", ".", ".."]

        private def validate_filename(filename)
          path = Path.posix(filename)

          if INVALID_FILENAMES.includes?(path.basename) || path.absolute? || path.parts.includes?("..")
            raise Errors::SuspiciousFileOperation.new("Unallowed file name detected: '#{filename}'")
          end

          filename
        end
      end
    end
  end
end
