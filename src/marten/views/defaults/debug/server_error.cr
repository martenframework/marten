module Marten
  module Views
    module Defaults
      module Debug
        class ServerError < View
          @error : Exception?
          @frames : Array(Frame)?

          def bind_error(error : Exception)
            @error = error
          end

          def dispatch
            if request.accepts?("text/html")
              render_server_error_page
            else
              HTTP::Response::ServerError.new(content: "Internal Server Error", content_type: "text/html")
            end
          end

          def error
            @error.not_nil!
          end

          def frames
            @frames ||= error.inspect_with_backtrace.scan(BACKTRACE_FRAME_RE).map_with_index do |matched_frame, index|
              Frame.new(
                matched_frame.named_captures["file"].not_nil!,
                matched_frame.named_captures["line_number"].not_nil!.to_i,
                index: index
              )
            end
          end

          private BACKTRACE_FRAME_RE = /\s(?<file>[^\s\:]+):(?<line_number>\d+)/

          private def render_server_error_page
            HTTP::Response.new(ECR.render("#{__DIR__}/templates/server_error.html.ecr"))
          end
        end
      end
    end
  end
end
