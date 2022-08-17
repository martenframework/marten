require "./spec_helper"

describe Marten::Views::Defaults::Debug::ServerError do
  describe "#bind_error" do
    it "associates an exception to the server error view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.error.should eq error
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

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(Exception.new("Something bad happened!"))
      response = view.dispatch
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

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(Exception.new("Something bad happened!"))
      response = view.dispatch
      response.status.should eq 500
      response.content_type.should eq "text/plain"
      response.content.includes?("Internal Server Error").should be_true
    end
  end

  describe "#error" do
    it "raiss a nil assertion error if no error was bound to the server error view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      view = Marten::Views::Defaults::Debug::ServerError.new(request)

      expect_raises(NilAssertionError) { view.error }
    end

    it "returns the error that was bound to the server error view" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/foo/bar",
          headers: HTTP::Headers{"Host" => "example.com", "Accept" => "text/html"}
        )
      )

      error = Exception.new("Something bad happened!")

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.error.should eq error
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

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.frames.should_not be_empty

      view.frames[0].filepath.should eq "spec/marten/views/defaults/debug/server_error_spec.cr"
      view.frames[0].index.should eq 0
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

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.template_snippet_lines.should be_nil
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

      view = Marten::Views::Defaults::Debug::ServerError.new(request)
      view.bind_error(error)

      view.template_snippet_lines.should be_nil
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

        view = Marten::Views::Defaults::Debug::ServerError.new(request)
        view.bind_error(error)

        view.template_snippet_lines.not_nil!.should_not be_empty
        view.template_snippet_lines.not_nil![0].should eq({"HEADER", 1, false})
        view.template_snippet_lines.not_nil![1].should eq({"Hello World, {% %}!", 2, true})
        view.template_snippet_lines.not_nil![2].should eq({"FOOTER", 3, false})
      end
    end
  end
end
