require "./spec_helper"

module Marten
  describe LiveReload do
    it "injects reload script into HTML responses when enabled" do
      original_settings = Marten.settings.debug?
      begin
        Marten.settings.debug = true
        Marten.settings.live_reload_enabled = true
        middleware = Marten::LiveReload.new

        response = Marten::HTTP::Response.new("<html><body>Test</body></html>", content_type: "text/html")

        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: ::HTTP::Headers{"Host" => "example.com"}
          )
        )
        response = middleware.call(request, -> { response })

        response.content.should contain("new EventSource('/live-reload')")
      ensure
        Marten.settings.debug = original_settings
      end
    end

    it "doesn't inject script when debug mode is disabled" do
      original_settings = Marten.settings.debug?
      begin
        Marten.settings.debug = false
        middleware = Marten::LiveReload.new

        response = Marten::HTTP::Response.new("<html><body>Test</body></html>", content_type: "text/html")

        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: ::HTTP::Headers{"Host" => "example.com"}
          )
        )
        response = middleware.call(request, -> { response })

        response.content.should_not contain("EventSource")
      ensure
        Marten.settings.debug = original_settings
      end
    end

    it "doesn't inject script for non-HTML responses" do
      original_settings = Marten.settings.debug?
      begin
        Marten.settings.debug = true
        middleware = Marten::LiveReload.new

        response = Marten::HTTP::Response.new("{\"test\": true}", content_type: "application/json")

        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: ::HTTP::Headers{"Host" => "example.com"}
          )
        )
        response = middleware.call(request, -> { response })

        response.content.should_not contain("EventSource")
      ensure
        Marten.settings.debug = original_settings
      end
    end

    it "doesn't inject script for AJAX requests" do
      original_settings = Marten.settings.debug?
      begin
        Marten.settings.debug = true
        middleware = Marten::LiveReload.new

        response = Marten::HTTP::Response.new("<html><body>Test</body></html>", content_type: "text/html")

        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: ::HTTP::Headers{"Host" => "example.com", "X-Requested-With" => "XMLHttpRequest"}
          )
        )
        response = middleware.call(request, -> { response })

        response.content.should_not contain("EventSource")
      ensure
        Marten.settings.debug = original_settings
      end
    end
  end
end
