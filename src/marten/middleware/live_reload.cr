module Marten
  # Middleware that injects the live reload script into HTML responses.
  # This middleware is only active in development mode when live reload is enabled.
  class LiveReload < Middleware
    @host : String
    @port : Int32

    def initialize
      super
      @host = Marten.settings.live_reload_host
      @port = Marten.settings.live_reload_port
    end

    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      response = get_response.call

      return response unless should_inject?(request, response)

      body = response.content.to_s
      insert_at = body.rindex("</body>")
      return response unless insert_at

      response.content = body.insert(insert_at, live_reload_script)
      response
    end

    private def should_inject?(request : Marten::HTTP::Request, response : Marten::HTTP::Response)
      return false unless Marten.settings.debug?
      return false unless Marten.settings.live_reload_enabled?
      return false unless response.content_type == "text/html"
      return false if request.headers["X-Requested-With"]? == "XMLHttpRequest"
      true
    end

    private def live_reload_script
      <<-SCRIPT
        <script>
          (function() {
            let ws = new WebSocket('ws://#{@host}:#{@port}/live_reload');
            
            ws.onmessage = function(msg) {
              if (msg.data === 'reload') {
                window.location.reload();
              }
            };
            
            ws.onclose = function() {
              // Try to reconnect if server temporarily down
              setTimeout(() => {
                ws = new WebSocket('ws://#{@host}:#{@port}/live_reload');
              }, 1000);
            };
          })();
        </script>
      SCRIPT
    end
  end
end
