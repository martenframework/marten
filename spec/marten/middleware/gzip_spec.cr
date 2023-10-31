require "./spec_helper"

describe Marten::Middleware::GZip do
  describe "#call" do
    it "does not compress short responses" do
      middleware = Marten::Middleware::GZip.new

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING]?.should be_nil
      response.content.should eq "It works!"
    end

    it "compresses long enough responses" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.content.should_not eq uncompressed_content

      Compress::Gzip::Reader.open(IO::Memory.new(response.content)) do |gzip|
        gzip.gets_to_end.should eq uncompressed_content
      end
    end

    it "does not compress long enough responses that contain a Content-Encoding header value" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{
          r = Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200)
          r.headers["Content-Encoding"] = "test"
          r
        }
      )

      response.headers[:CONTENT_ENCODING]?.should eq "test"
      response.content.should eq uncompressed_content
    end

    it "patches the Vary header accordingly" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.headers[:VARY].should eq "Accept-Encoding"
    end

    it "does not compress long enough responses if the browser does not support GZip compression" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING]?.should be_nil
      response.content.should eq uncompressed_content
    end

    it "marks a non-weak ETag header as weak" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{
          r = Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200)
          r.headers["ETag"] = %{"33a64df551425fcc55e4d42a148795d9f25f89d4"}
          r
        }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.headers["ETag"].should eq %{W/"33a64df551425fcc55e4d42a148795d9f25f89d4"}
    end

    it "does not modify an already weak ETag header" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{
          r = Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200)
          r.headers["ETag"] = %{W/"33a64df551425fcc55e4d42a148795d9f25f89d4"}
          r
        }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.headers["ETag"].should eq %{W/"33a64df551425fcc55e4d42a148795d9f25f89d4"}
    end

    it "properly sets the Content-Length header when a compression is done" do
      middleware = Marten::Middleware::GZip.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.content.should_not eq uncompressed_content
      response.headers[:CONTENT_LENGTH].should eq response.content.bytesize.to_s
    end

    it "adds a random number of bytes to mitigate the BREACH attack" do
      middleware = Marten::Middleware::GZipSpec::DeterministicMiddleware.new

      uncompressed_content = "It works!" * 100

      response = middleware.call(
        Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{
              "Host"            => "example.com",
              "Accept-Encoding" => "gzip, deflate, br",
            }
          )
        ),
        ->{ Marten::HTTP::Response.new(uncompressed_content, content_type: "text/plain", status: 200) }
      )

      response.headers[:CONTENT_ENCODING].should eq "gzip"
      response.content.should_not eq uncompressed_content

      Compress::Gzip::Reader.open(IO::Memory.new(response.content)) do |gzip|
        gzip.gets_to_end.should eq uncompressed_content
        gzip.header.not_nil!.name.should eq middleware.random_filename
      end
    end
  end
end

module Marten::Middleware::GZipSpec
  class DeterministicMiddleware < Marten::Middleware::GZip
    def random_filename
      "aaaaaaa"
    end
  end
end
