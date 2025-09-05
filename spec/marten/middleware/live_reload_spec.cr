require "./spec_helper"

describe Marten::Middleware::LiveReload do
  it "injects reload script into HTML responses when enabled" do
    original_settings = Marten.settings.debug?
    begin
      Marten.settings.debug = true
      middleware = Marten::Middleware::LiveReload.new

      response = HTTP::Response.new(
        content_type: "text/html",
        content: "<html><body>Test</body></html>"
      )

      request = HTTP::Request.new("GET", "/")
      response = middleware.process_request(request) { response }

      response.content.should contain("new WebSocket('ws://localhost:35729/live_reload')")
    ensure
      Marten.settings.debug = original_settings
    end
  end

  it "doesn't inject script when debug mode is disabled" do
    original_settings = Marten.settings.debug?
    begin
      Marten.settings.debug = false
      middleware = Marten::Middleware::LiveReload.new

      response = HTTP::Response.new(
        content_type: "text/html",
        content: "<html><body>Test</body></html>"
      )

      request = HTTP::Request.new("GET", "/")
      response = middleware.process_request(request) { response }

      response.content.should_not contain("WebSocket")
    ensure
      Marten.settings.debug = original_settings
    end
  end

  it "doesn't inject script for non-HTML responses" do
    original_settings = Marten.settings.debug?
    begin
      Marten.settings.debug = true
      middleware = Marten::Middleware::LiveReload.new

      response = HTTP::Response.new(
        content_type: "application/json",
        content: "{\"test\": true}"
      )

      request = HTTP::Request.new("GET", "/")
      response = middleware.process_request(request) { response }

      response.content.should_not contain("WebSocket")
    ensure
      Marten.settings.debug = original_settings
    end
  end

  it "doesn't inject script for AJAX requests" do
    original_settings = Marten.settings.debug?
    begin
      Marten.settings.debug = true
      middleware = Marten::Middleware::LiveReload.new

      response = HTTP::Response.new(
        content_type: "text/html",
        content: "<html><body>Test</body></html>"
      )

      request = HTTP::Request.new("GET", "/")
      request.headers["X-Requested-With"] = "XMLHttpRequest"
      response = middleware.process_request(request) { response }

      response.content.should_not contain("WebSocket")
    ensure
      Marten.settings.debug = original_settings
    end
  end
end
