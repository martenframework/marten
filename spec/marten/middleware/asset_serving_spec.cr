require "./spec_helper"

describe Marten::Middleware::AssetServing do
  around_each do |t|
    with_overridden_setting("assets.url", "/assets/") do
      with_overridden_setting("assets.root", File.join(__DIR__, "asset_serving/assets")) do
        t.run
      end
    end
  end

  describe "#call" do
    it "returns the next response early if the request path does not match the configured assets URL" do
      middleware = Marten::Middleware::AssetServing.new

      response_1 = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )
      response_1.content.should eq "It works!"

      response_2 = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/foo/bar",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )
      response_2.content.should eq "It works!"
    end

    it "returns the next response early if the asset path does not exist" do
      middleware = Marten::Middleware::AssetServing.new

      response_1 = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/assets/unknown.css",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
      )
      response_1.content.should eq "Unknown!"

      response_2 = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/assets/css/unknown.css",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
      )
      response_2.content.should eq "Unknown!"
    end

    it "returns the next response early if a path traversal is attempted" do
      middleware = Marten::Middleware::AssetServing.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/assets/../../asset_serving_spec.cr",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
      )
      response.content.should eq "Unknown!"
    end

    it "returns the next response early if the specified path is a directory" do
      middleware = Marten::Middleware::AssetServing.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "/assets/css",
            headers: HTTP::Headers{"Host" => "example.com", "Accept-Language" => "fr,en;q=0.5"}
          )
        ),
        ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
      )
      response.content.should eq "Unknown!"
    end

    it "does not compress small asset files" do
      middleware = Marten::Middleware::AssetServing.new

      ["SmallApp.js", "css/SmallApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "gzip, deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING]?.should be_nil
        response.content.should eq File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
      end
    end

    it "does not compress if GZip and deflate are not supported" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host" => "example.com",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING]?.should be_nil
        response.content.should eq File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
      end
    end

    it "compresses using GZip over other supported encoding" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "gzip, deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING].should eq "gzip"

        uncompressed_content = File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
        response.content.should_not eq uncompressed_content

        Compress::Gzip::Reader.open(IO::Memory.new(response.content)) do |gzip|
          gzip.gets_to_end.should eq uncompressed_content
        end
      end
    end

    it "fallbacks to using deflate if GZip is not supported" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING].should eq "deflate"

        uncompressed_content = File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
        response.content.should_not eq uncompressed_content

        Compress::Deflate::Reader.open(IO::Memory.new(response.content)) do |deflate|
          deflate.gets_to_end.should eq uncompressed_content
        end
      end
    end

    it "properly sets the Content-Length header" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "gzip, deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING].should eq "gzip"

        uncompressed_content = File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
        response.content.should_not eq uncompressed_content
        response.headers[:CONTENT_LENGTH].should eq response.content.bytesize.to_s
      end
    end

    it "properly sets the ETag header using the file modification time" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "gzip, deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING].should eq "gzip"

        uncompressed_content = File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
        response.content.should_not eq uncompressed_content
        response.headers[:"ETag"].should eq(
          %{W/"#{File.info(File.join(__DIR__, "asset_serving/assets/#{path}")).modification_time.to_unix}"}
        )
      end
    end

    it "properly sets the Cache-Control header" do
      middleware = Marten::Middleware::AssetServing.new

      ["BigApp.js", "css/BigApp.css"].each do |path|
        response = middleware.call(
          Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/assets/#{path}",
              headers: HTTP::Headers{
                "Host"            => "example.com",
                "Accept-Encoding" => "gzip, deflate, br",
              }
            )
          ),
          ->{ Marten::HTTP::Response.new("Unknown!", content_type: "text/plain", status: 200) }
        )

        response.headers[:CONTENT_ENCODING].should eq "gzip"

        uncompressed_content = File.read(File.join(__DIR__, "asset_serving/assets/#{path}"))
        response.content.should_not eq uncompressed_content
        response.headers[:"Cache-Control"].should eq "private, max-age=3600"
      end
    end
  end
end
