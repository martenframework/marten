module Marten
  module DB
    module Field
      # Represents a file field's value.
      #
      # Instances of this class give access to the properties of a file manipulated by a `file` field. They allow to
      # read a file's content, and to attach new files to model records.
      class File < Base
        class File
          @committed = true
          @file : ::File | HTTP::UploadedFile | Nil = nil
          @record : Model? = nil

          # :nodoc:
          getter file

          # Returns the name of the file or `nil` if no file is set.
          getter name

          # :nodoc:
          getter record

          # :nodoc:
          setter committed

          # Allows to associate a new file to the field.
          setter file

          # :nodoc:
          setter record

          def initialize(@field : Field::File, @name : ::String? = nil)
          end

          # Returns `true` if a file is attached to the field and record.
          def attached?
            !@name.nil?
          end

          # Returns `true` if the file is committed to the underlying storage.
          def committed?
            @committed
          end

          # Deletes the associated filfe from the storage.
          #
          # A `Marten::DB::Errors::UnexpectedFieldValue` error is raised if no file is associated with this object.
          # Optionally, a `save` boolean can be set to force the associated record to be saved along the way.
          def delete(save = false) : Nil
            with_ensured_file do
              @field.storage.delete(name!)
              self.file = nil
              self.name = nil
              self.committed = false

              record!.save if save
            end
          end

          # Returns a `IO` object allowing to interact with the file's content.
          #
          # A `Marten::DB::Errors::UnexpectedFieldValue` error is raised if no file is associated with this object.
          def open : IO
            with_ensured_file do
              if !committed?
                case f = file
                when ::File
                  f
                when HTTP::UploadedFile
                  f.io
                end.not_nil!
              else
                @field.storage.open(name!)
              end
            end
          end

          # Allows to save a new file to the underlying storage.
          #
          # A `filepath` string and a `content` IO must be specified. Optionally, a `save` boolean can be set to force
          # the associated record to be saved along the way.
          def save(filepath : ::String, content : IO, save = false) : Nil
            self.name = @field.storage.save(field.sanitize_filename(filepath), content)
            self.committed = true

            record!.save if save
          end

          # Returns the `size` of the file.
          #
          # A `Marten::DB::Errors::UnexpectedFieldValue` error is raised if no file is associated with this object.
          def size : Int64
            with_ensured_file do
              if !committed?
                file.not_nil!.size.try(&.to_i64).not_nil!
              else
                @field.storage.size(name!)
              end
            end
          end

          # Returns the URL of the file.
          #
          # A `Marten::DB::Errors::UnexpectedFieldValue` error is raised if no file is associated with this object.
          def url : ::String
            with_ensured_file do
              @field.storage.url(name.not_nil!)
            end
          end

          private getter field

          private setter name

          private def name!
            name.not_nil!
          end

          private def record!
            record.not_nil!
          end

          private def with_ensured_file(&)
            raise Errors::UnexpectedFieldValue.new("No file available") if name.nil?
            yield
          end
        end
      end
    end
  end
end
