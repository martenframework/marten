require "./spec_helper"

describe Marten::Handlers::Defaults::Development::ServeMediaFile do
  describe "#get" do
    it "returns the content of a specific media file with the right content type" do
      dir_path = File.join(Marten.settings.media_files.root, "test")
      file_path = File.join(dir_path, "test.txt")

      FileUtils.mkdir_p(dir_path)
      File.write(file_path, "Hello World")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "test/test.txt"}
      handler = Marten::Handlers::Defaults::Development::ServeMediaFile.new(request, params)

      response = handler.dispatch

      response.status.should eq 200
      response.content_type.should eq MIME.from_filename(file_path)
      response.content.should eq File.read(file_path)
    end

    it "returns a 404 response if the media file cannot be found" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "test/unknown.txt"}
      handler = Marten::Handlers::Defaults::Development::ServeMediaFile.new(request, params)

      response = handler.dispatch

      response.status.should eq 404
    end

    it "returns a 404 response if the passed path corresponds to a directory" do
      FileUtils.mkdir_p(File.join(Marten.settings.media_files.root, "test"))

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      params = Marten::Routing::MatchParameters{"path" => "test"}
      handler = Marten::Handlers::Defaults::Development::ServeMediaFile.new(request, params)

      response = handler.dispatch

      response.status.should eq 404
    end
  end
end
