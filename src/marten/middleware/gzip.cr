module Marten
  abstract class Middleware
    # Compresses the content of the response if the browser supports GZip compression.
    #
    # This middleware will compress responses that are big enough (200 bytes or more) if they don't already contain an
    # Accept-Encoding header. It will also set the Vary header correctly by including Accept-Encoding in it so that
    # caches take into account the fact that the content can be compressed or not.
    class GZip < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        response = get_response.call

        # Don't compress streaming responses.
        return response if response.is_a?(HTTP::Response::Streaming)

        # Don't compress short responses as this is not worth it.
        return response if response.content.bytesize < SHORT_RESPONSE_SIZE_THRESHOLD

        # Don't compress responses that contain an explicit Content-Encoding header.
        return response if response.headers[:CONTENT_ENCODING]?

        # Ensures the Vary header includes Accept-Encoding so that caches take it into account.
        response.headers.patch_vary("Accept-Encoding")

        # Only proceed with the GZip compression if the browser actually supports it.
        return response unless request.headers.fetch(:ACCEPT_ENCODING, "").matches?(GZIP_ACCEPT_ENCODING_RE)

        compressed_content = compress(response.content)
        return response if compressed_content.bytesize >= response.content.bytesize

        response.content = compressed_content
        response.headers["Content-Length"] = compressed_content.bytesize

        # Ensures that any etag is weak to comply with RFC 7232.
        etag = response.headers[:"ETag"]?
        if !etag.nil? && etag.starts_with?('"')
          response.headers[:"ETag"] = "W/" + etag
        end

        response.headers[:"Content-Encoding"] = "gzip"

        response
      end

      private GZIP_ACCEPT_ENCODING_RE       = /\bgzip\b/i
      private SHORT_RESPONSE_SIZE_THRESHOLD = 200

      private def compress(content)
        compressed_io = IO::Memory.new

        Compress::Gzip::Writer.open(compressed_io) do |gzip|
          IO.copy(IO::Memory.new(content), gzip)
        end

        compressed_content = compressed_io.rewind.gets_to_end
        compressed_io.close

        compressed_content
      end
    end
  end
end
