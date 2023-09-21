require "./spec_helper"

describe Marten::Handlers::Defaults::Development::ServeAsset do
  describe "#get" do
    it "returns the content of a specific asset with the richt content type" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "css/test.css"}
      handler = Marten::Handlers::Defaults::Development::ServeAsset.new(request, params)

      response = handler.dispatch

      response.status.should eq 200
      response.content_type.should eq MIME.from_filename("css/test.css")
      response.content.should eq File.read(Marten.assets.find("css/test.css"))
    end

    it "returns a default content type if no content type can be determined for the given asset path" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "unidentified_file"}
      handler = Marten::Handlers::Defaults::Development::ServeAsset.new(request, params)

      response = handler.dispatch

      response.status.should eq 200
      response.content_type.should eq "application/octet-stream"
      response.content.should eq File.read(Marten.assets.find("unidentified_file"))
    end

    it "returns a 404 response if the asset cannot be found" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "css/unknown.css"}
      handler = Marten::Handlers::Defaults::Development::ServeAsset.new(request, params)

      response = handler.dispatch

      response.status.should eq 404
    end

    it "returns a 404 response if the passed path corresponds to a directory" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "css"}
      handler = Marten::Handlers::Defaults::Development::ServeAsset.new(request, params)

      response = handler.dispatch

      response.status.should eq 404
    end
  end
end
