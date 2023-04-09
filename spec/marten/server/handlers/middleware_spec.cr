require "./spec_helper"

describe Marten::Server::Handlers::Middleware do
  describe "#call" do
    it "completes as expected in case no middlewares are configured" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Middleware.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        ctx.marten.response = Marten::HTTP::Response.new("It works", status: 200)
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      with_overridden_setting("middleware", [] of Marten::Middleware.class) do
        handler.call(ctx)
      end

      output_io.rewind.gets.should eq "It works"
    end

    it "calls the configured middlewares as expected in the right order" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Middleware.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        ctx.marten.response = Marten::HTTP::Response.new("It works", status: 200)
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      with_overridden_setting(
        "middleware",
        [Marten::Server::Handlers::MiddlewareSpec::Middleware1, Marten::Server::Handlers::MiddlewareSpec::Middleware2]
      ) do
        handler.call(ctx)
      end

      output_io.rewind.gets.should eq "It works"
      ctx.response.headers["X-Middleware"].should eq "1,2"
    end
  end
end

module Marten::Server::Handlers::MiddlewareSpec
  class Middleware1 < Marten::Middleware
    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      response = get_response.call
      response.headers["X-Middleware"] += ",2"
      response
    end
  end

  class Middleware2 < Marten::Middleware
    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      response = get_response.call
      response.headers["X-Middleware"] = "1"
      response
    end
  end
end
