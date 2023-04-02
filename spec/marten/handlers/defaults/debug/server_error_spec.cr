require "./spec_helper"

describe Marten::Handlers::Defaults::Debug::ServerError do
  describe "#bind_error" do
    it "associates an exception to the server error handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.error.should eq error
    end
  end

  describe "#dispatch" do
    it "returns a server error page if the incoming request accepts HTML content" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(Exception.new("Something bad happened!"))
      response = handler.dispatch
      response.status.should eq 500
      response.content_type.should eq "text/html"
      response.content.includes?("Something bad happened!").should be_true
    end

    it "returns a raw server error response if the incoming request does not accept HTML content" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "application/json"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(Exception.new("Something bad happened!"))
      response = handler.dispatch
      response.status.should eq 500
      response.content_type.should eq "text/plain"
      response.content.includes?("Internal Server Error").should be_true
    end
  end

  describe "#error" do
    it "raises a nil assertion error if no error was bound to the server error handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)

      expect_raises(NilAssertionError) { handler.error }
    end

    it "returns the error that was bound to the server error handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.error.should eq error
    end
  end

  describe "#frames" do
    it "returns the expected frame objects" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = expect_raises(Exception) do
        raise "Something bad happened!"
      end

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.frames.should_not be_empty

      handler.frames[0].filepath.should eq "spec/marten/handlers/defaults/debug/server_error_spec.cr"
      handler.frames[0].index.should eq 0
    end

    it "does not extract host and ports as frames" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = expect_raises(Exception) do
        raise "Something bad happened when reaching 192.168.1.1:8000!"
      end

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.frames.should_not be_empty

      handler.frames[0].filepath.should eq "spec/marten/handlers/defaults/debug/server_error_spec.cr"
      handler.frames[0].index.should eq 0
    end
  end

  describe "#status=" do
    it "allows to override the status returned by the handler" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.status = 400
      handler.bind_error(Marten::HTTP::Errors::SuspiciousOperation.new("This is bad"))

      response = handler.dispatch
      response.status.should eq 400
      response.content_type.should eq "text/html"
    end
  end

  describe "#template_snippet_lines" do
    it "returns nil if the error is not a template syntax error" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = expect_raises(Exception) do
        raise "Something bad happened!"
      end

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.template_snippet_lines.should be_nil
    end

    it "returns nil if the error is a template syntax error that wasn't decorated properly" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Marten::Template::Errors::InvalidSyntax.new("Something bad happened!")

      handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
      handler.bind_error(error)

      handler.template_snippet_lines.should be_nil
    end

    it "returns the expected template snippet lines if the error is a template syntax error" do
      with_overridden_setting(:debug, true) do
        source = <<-TEMPLATE
        HEADER
        Hello World, {% %}!
        FOOTER
        TEMPLATE

        parser = Marten::Template::Parser.new(source)

        error = expect_raises(
          Marten::Template::Errors::InvalidSyntax,
          "Empty tag detected on line 2"
        ) do
          parser.parse
        end

        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/foo/bar",
            headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
          )
        )

        handler = Marten::Handlers::Defaults::Debug::ServerError.new(request)
        handler.bind_error(error)

        handler.template_snippet_lines.not_nil!.should_not be_empty
        handler.template_snippet_lines.not_nil![0].should eq({"HEADER", 1, false})
        handler.template_snippet_lines.not_nil![1].should eq({"Hello World, {% %}!", 2, true})
        handler.template_snippet_lines.not_nil![2].should eq({"FOOTER", 3, false})
      end
    end
  end
end
