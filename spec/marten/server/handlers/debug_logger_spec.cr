require "./spec_helper"

describe Marten::Server::Handlers::DebugLogger do
  describe "#call" do
    it "generates the expected log entries before and after the request completion" do
      output_io = IO::Memory.new

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler = Marten::Server::Handlers::DebugLogger.new
      handler.next = HTTP::Handler::HandlerProc.new do |handler_ctx|
        handler_ctx.response.output = output_io
        handler_ctx.response.print("It works")
      end

      Log.capture do |logs|
        with_overridden_setting("debug", true) do
          handler.call(ctx)
        end

        logs.check(:info, /Started \"GET \/foo\/bar\"/i)
        logs.next(:info, /Completed with \"200\"/i)
      end
    end

    it "generates additional log entries when data is present" do
      output_io = IO::Memory.new

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Content-Type" => "application/x-www-form-urlencoded"},
          body: "foo=bar&test=xyz"
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler = Marten::Server::Handlers::DebugLogger.new
      handler.next = HTTP::Handler::HandlerProc.new do |handler_ctx|
        handler_ctx.response.output = output_io
        handler_ctx.response.print("It works")
      end

      Log.capture do |logs|
        with_overridden_setting("debug", true) do
          handler.call(ctx)
        end

        logs.check(:info, /Started \"GET \/foo\/bar\"/i)
        logs.next(:info, /Data: {\"foo\" => \[\"bar\"\], \"test\" => \[\"xyz\"\]}/i)
        logs.next(:info, /Completed with \"200\"/i)
      end
    end

    it "generates additional log entries when query params are present" do
      output_io = IO::Memory.new

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar?foo=bar&test=xyz",
          headers: HTTP::Headers{"Host" => "example.com"},
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler = Marten::Server::Handlers::DebugLogger.new
      handler.next = HTTP::Handler::HandlerProc.new do |handler_ctx|
        handler_ctx.response.output = output_io
        handler_ctx.response.print("It works")
      end

      Log.capture do |logs|
        with_overridden_setting("debug", true) do
          handler.call(ctx)
        end

        logs.check(:info, /Started \"GET \/foo\/bar\"/i)
        logs.next(:info, /Query params: {\"foo\" => \[\"bar\"\], \"test\" => \[\"xyz\"\]}/i)
        logs.next(:info, /Completed with \"200\"/i)
      end
    end
  end
end
