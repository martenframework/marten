require "./spec_helper"

describe Marten::Server::Handlers::HandlerResponseConverter do
  describe "#convert_handler_response" do
    it "sets the response status code as expected" do
      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      response = Marten::HTTP::Response.new("It works", status: 204)

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      ctx.response.status_code.should eq 204
    end

    it "sets the response headers as expected" do
      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      response = Marten::HTTP::Response.new("It works", status: 200)
      response.headers["Content-Length"] = 1000
      response.headers["X-App-Foo"] = "bar"

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      ctx.response.headers["Content-Length"].should eq "1000"
      ctx.response.headers["X-App-Foo"].should eq "bar"
    end

    it "sets the response content type as expected" do
      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      response = Marten::HTTP::Response.new("It works", status: 204, content_type: "text/csv")

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      ctx.response.headers["Content-Type"].should eq "text/csv"
    end

    it "sets cookies set on the request as expected" do
      ctx = HTTP::Server::Context.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      ctx.marten.request.cookies["foo"] = "bar"

      response = Marten::HTTP::Response.new("It works", status: 204)

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      ctx.response.cookies["foo"].value.should eq "bar"
    end

    it "sets cookies set on the response as expected" do
      ctx = HTTP::Server::Context.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )

      response = Marten::HTTP::Response.new("It works", status: 204)
      response.cookies["foo"] = "bar"

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      ctx.response.cookies["foo"].value.should eq "bar"
    end

    it "prints the response content as expected" do
      output_io = IO::Memory.new

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )
      ctx.response.output = output_io

      response = Marten::HTTP::Response.new("It works", status: 204)

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      output_io.rewind.gets_to_end.should eq "It works"
    end

    it "prints a response's streamed content as expected" do
      output_io = Marten::Server::Handlers::HandlerResponseConverterSpec::StreamedIO.new

      ctx = HTTP::Server::Context.new(
        request: ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "FR,en;q=0.5"}
        ),
        response: ::HTTP::Server::Response.new(io: IO::Memory.new)
      )
      ctx.response.output = output_io

      response = Marten::HTTP::Response::Streaming.new(["foo", "bar", "xyz", "test"].each)

      test = Marten::Server::Handlers::HandlerResponseConverterSpec::Test.new
      test.convert_handler_response(ctx, response)

      output_io.slices.map { |slice| String.new(slice) }.should eq ["foo", "bar", "xyz", "test"]
    end
  end
end

module Marten::Server::Handlers::HandlerResponseConverterSpec
  class Test
    include Marten::Server::Handlers::HandlerResponseConverter
  end

  class StreamedIO < IO::Memory
    @slices = [] of Bytes

    getter slices

    def write(slice : Bytes) : Nil
      @slices << slice
      super
    end
  end
end
