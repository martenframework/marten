require "./spec_helper"

describe Marten::Server::Handlers::Error do
  describe "#call" do
    it "completes as expected in case of no errors" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        ctx.response.print("It works")
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.should eq "It works"
    end

    it "calls the page not found handler in case of a Marten::HTTP::Errors::NotFound error" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        raise Marten::HTTP::Errors::NotFound.new("This is bad")
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.not_nil!.includes?("The requested resource was not found")
    end

    it "calls the page not found handler in case of a Marten::Routing::Errors::NoResolveMatch error" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        raise Marten::Routing::Errors::NoResolveMatch.new("This is bad")
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.not_nil!.includes?("The requested resource was not found")
    end

    it "calls the bad request handler in case of a Marten::HTTP::Errors::SuspiciousOperation error" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        raise Marten::HTTP::Errors::SuspiciousOperation.new("This is bad")
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.not_nil!.includes?("Bad Request")
    end

    it "calls the debug server error handler in case of a Marten::HTTP::Errors::SuspiciousOperation error in debug" do
      with_overridden_setting("debug", true) do
        output_io = IO::Memory.new
        handler = Marten::Server::Handlers::Error.new
        handler.next = HTTP::Handler::HandlerProc.new do |ctx|
          ctx.response.output = output_io
          raise Marten::HTTP::Errors::SuspiciousOperation.new("This is bad")
        end

        ctx = HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        handler.call(ctx)

        ctx.response.status_code.should eq 400

        output = output_io.rewind.gets.not_nil!
        output.includes?("Marten::HTTP::Errors::SuspiciousOperation at")
        output.includes?("Traceback")
        output.includes?("General information")
      end
    end

    it "calls the permission denied handler in case of a Marten::HTTP::Errors::PermissionDenied error" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        raise Marten::HTTP::Errors::PermissionDenied.new("This is bad")
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.not_nil!.includes?("403 Forbidden")
    end

    it "calls the server error handler in case of any other error" do
      output_io = IO::Memory.new
      handler = Marten::Server::Handlers::Error.new
      handler.next = HTTP::Handler::HandlerProc.new do |ctx|
        ctx.response.output = output_io
        1 // 0
      end

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      handler.call(ctx)

      output_io.rewind.gets.not_nil!.includes?("Internal Server Error")
    end
  end
end
