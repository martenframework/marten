module Marten
  module Handlers
    module Defaults
      module Debug
        # Handles server errors in debug mode.
        class ServerError < Handler
          @error : Exception?
          @frames : Array(Frame)?
          @status : Int32 = 500

          setter status

          def bind_error(error : Exception)
            @error = error
          end

          def dispatch
            if request.accepts?("text/html")
              render_server_error_page
            else
              HTTP::Response.new(content: "Internal Server Error", content_type: "text/plain", status: status)
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

          def template_snippet_lines
            return if !error.is_a?(Marten::Template::Errors::InvalidSyntax)

            tpl_error = error.as(Marten::Template::Errors::InvalidSyntax)

            return if tpl_error.source.nil? || tpl_error.token.nil?

            lines = [] of Tuple(String, Int32, Bool)

            errored_line_number = tpl_error.token.not_nil!.line_number
            lines += tpl_error.source.not_nil!.lines.map_with_index do |code, line_index|
              next unless (errored_line_number - 10..errored_line_number + 10).includes?(line_index + 1)
              {code, line_index + 1, line_index + 1 == errored_line_number}
            end

            lines.compact
          end

          private BACKTRACE_FRAME_RE = /\sfrom (?<file>[^\s\:]+):(?<line_number>\d+)/

          private getter status

          private def render_server_error_page
            HTTP::Response.new(content: ECR.render("#{__DIR__}/templates/server_error.html.ecr"), status: status)
          end
        end
      end
    end
  end
end
