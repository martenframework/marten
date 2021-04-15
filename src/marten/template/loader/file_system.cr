module Marten
  module Template
    module Loader
      # A simple template loader that reads template contents from the file system.
      class FileSystem < Base
        getter path

        def initialize(@path : String)
        end

        def get_template(template_name) : Template
          super
        rescue e : Errors::InvalidSyntax
          if Marten.settings.debug && e.filepath.nil?
            e.filepath = File.join(@path, template_name).to_s
          end

          raise e
        end

        def get_template_source(template_name) : String
          template_fpath = File.join(@path, template_name)

          if File.exists?(template_fpath)
            begin
              return File.read(template_fpath)
            rescue e : IO::Error | File::Error
              raise Errors::TemplateNotFound.new("Template #{template_name} could not be found ; #{e.message}", e)
            end
          end

          raise Errors::TemplateNotFound.new("Template #{template_name} could not be found")
        end
      end
    end
  end
end
