module Marten
  # Middleware that injects the live reload script into HTML responses.
  # This middleware is only active in development mode when live reload is enabled.
  class LiveReload < Middleware
    def call(request : HTTP::Request, get_response : Proc(HTTP::Response)) : HTTP::Response
      response = get_response.call

      return response unless should_inject?(request, response)

      body = response.content.to_s
      # Find the position of </body> tag (case-insensitive)
      insert_at = body.downcase.rindex("</body>")
      return response unless insert_at

      script = {{ read_file "#{__DIR__}/live_reload.html" }}

      response.content = body.insert(insert_at, script)
      response
    end

    private def should_inject?(request : HTTP::Request, response : HTTP::Response)
      return false unless Marten.settings.debug?
      return false unless Marten.settings.live_reload_enabled?
      return false unless response.content_type.downcase.starts_with?("text/html")
      return false if request.headers["X-Requested-With"]? == "XMLHttpRequest"
      true
    end
  end
end
