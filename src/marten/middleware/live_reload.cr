module Marten
  module Middleware
    # Middleware that injects the live reload script into HTML responses.
    # This middleware is only active in development mode when live reload is enabled.
    class LiveReload < Base
      def initialize
        @host = Marten.settings.live_reload_host
        @port = Marten.settings.live_reload_port
      end

      def process_request(request, get_response)
        response = get_response.call(request)

        return response unless should_inject?(request, response)

        body = response.content.to_s
        insert_at = body.rindex("</body>")
        return response unless insert_at

        response.content = body.insert(insert_at, live_reload_script)
        response
      end

      private def should_inject?(request, response)
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
end
