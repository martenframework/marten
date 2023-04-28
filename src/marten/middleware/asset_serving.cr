module Marten
  abstract class Middleware
    # Allows serving compressed static assets.
    #
    # This middleware serves the collected assets that are available under the configured assets root (`assets.root`
    # setting). This assumes that the assets under this folder have been "collected" by using the `collectassets`
    # management command and that the assets storage being used is the "file system" one
    # (`Marten::Core::Storage::FileSystem`).
    #
    # It should also be noted that this middleware will automatically compress served assets using GZip or deflate based
    # on the incoming Accept-Encoding header. The middleware also sets the Cache-Control header and specifies a max-age
    # of 3600s.
    class AssetServing < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        return get_response.call if !request.path.starts_with?(Marten.settings.assets.url)

        asset_file_path = File.expand_path(
          File.join(
            expanded_assets_path,
            File.expand_path(request.path, "/").lchop(Marten.settings.assets.url)
          ),
          "/"
        )

        if asset_file_path.starts_with?(expanded_assets_path) && File.exists?(asset_file_path) &&
           !File.directory?(asset_file_path)
          serve_asset_file(request, asset_file_path)
        else
          get_response.call
        end
      end

      private DEFLATE_ACCEPT_ENCODING_RE = /\bdeflate\b/i
      private GZIP_ACCEPT_ENCODING_RE    = /\bgzip\b/i
      private SMALL_FILE_SIZE_THRESHOLD  = 200

      private def accepts_deflate_encoding?(request : HTTP::Request) : Bool
        request.headers.fetch(:ACCEPT_ENCODING, "").matches?(DEFLATE_ACCEPT_ENCODING_RE)
      end

      private def accepts_gzip_encoding?(request : HTTP::Request) : Bool
        request.headers.fetch(:ACCEPT_ENCODING, "").matches?(GZIP_ACCEPT_ENCODING_RE)
      end

      private def expanded_assets_path : String
        @expanded_assets_path ||= Path[Marten.settings.assets.root].expand.to_s
      end

      private def compress_using_deflate(file : File, io : IO) : Nil
        Compress::Deflate::Writer.open(io) do |deflate|
          IO.copy(file, deflate)
        end
      end

      private def compress_using_gzip(file : File, io : IO) : Nil
        Compress::Gzip::Writer.open(io) do |gzip|
          IO.copy(file, gzip)
        end
      end

      private def serve_asset_file(request : HTTP::Request, asset_file_path : String) : Marten::HTTP::Response
        asset_file_size = File.size(asset_file_path)

        content_type = begin
          MIME.from_filename(asset_file_path)
        rescue KeyError
          "application/octet-stream"
        end

        content_encoding = nil

        served_asset_io = IO::Memory.new

        File.open(asset_file_path) do |asset_file|
          if accepts_gzip_encoding?(request) && asset_file_size >= SMALL_FILE_SIZE_THRESHOLD
            compress_using_gzip(asset_file, served_asset_io)
            content_encoding = "gzip"
          elsif accepts_deflate_encoding?(request) && asset_file_size >= SMALL_FILE_SIZE_THRESHOLD
            compress_using_deflate(asset_file, served_asset_io)
            content_encoding = "deflate"
          else
            IO.copy(asset_file, served_asset_io)
          end
        end

        response = HTTP::Response.new(content: served_asset_io.rewind.gets_to_end, content_type: content_type)
        served_asset_io.close

        response.headers[:"Content-Length"] = response.content.bytesize
        response.headers[:"ETag"] = %{W/"#{File.info(asset_file_path).modification_time.to_unix}"}
        response.headers[:"Content-Encoding"] = content_encoding if !content_encoding.nil?
        response.headers[:"Cache-Control"] = "private, max-age=3600"

        response
      end
    end
  end
end
