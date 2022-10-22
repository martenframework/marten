require "./spec_helper"

describe Marten::Middleware::StrictTransportSecurity do
  describe "#call" do
    it "returns the response early if it the max_age setting is set to nil" do
      with_overridden_setting("strict_transport_security.max_age", nil, nilable: true) do
        with_overridden_setting("use_x_forwarded_proto", true) do
          request = Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/test/xyz",
              headers: HTTP::Headers{
                "Host"              => "example.com",
                "X-Forwarded-Proto" => "https",
              },
            )
          )

          middleware = Marten::Middleware::StrictTransportSecurity.new
          response = middleware.call(
            request,
            ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
          )

          response.headers.has_key?(:"Strict-Transport-Security").should be_false
        end
      end
    end

    it "returns the response early if the request is not secure" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("use_x_forwarded_proto", false) do
          request = Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/test/xyz",
              headers: HTTP::Headers{"Host" => "example.com"},
            )
          )

          middleware = Marten::Middleware::StrictTransportSecurity.new
          response = middleware.call(
            request,
            ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
          )

          response.headers.has_key?(:"Strict-Transport-Security").should be_false
        end
      end
    end

    it "returns the response early if it already contains the Strict-Transport-Security header" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("use_x_forwarded_proto", true) do
          request = Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/test/xyz",
              headers: HTTP::Headers{
                "Host"              => "example.com",
                "X-Forwarded-Proto" => "https",
              },
            )
          )

          middleware = Marten::Middleware::StrictTransportSecurity.new
          response = middleware.call(
            request,
            ->{
              r = Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
              r[:"Strict-Transport-Security"] = "max-age=3600"
              r
            }
          )

          response.headers[:"Strict-Transport-Security"].should eq "max-age=3600"
        end
      end
    end

    it "includes the expected header when a max age is configured" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("use_x_forwarded_proto", true) do
          request = Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "/test/xyz",
              headers: HTTP::Headers{
                "Host"              => "example.com",
                "X-Forwarded-Proto" => "https",
              },
            )
          )

          middleware = Marten::Middleware::StrictTransportSecurity.new
          response = middleware.call(
            request,
            ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
          )

          response.headers[:"Strict-Transport-Security"].should eq "max-age=31536000"
        end
      end
    end

    it "includes the expected header when a max age and is configured and sub domains are included" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("strict_transport_security.include_sub_domains", true) do
          with_overridden_setting("use_x_forwarded_proto", true) do
            request = Marten::HTTP::Request.new(
              ::HTTP::Request.new(
                method: "GET",
                resource: "/test/xyz",
                headers: HTTP::Headers{
                  "Host"              => "example.com",
                  "X-Forwarded-Proto" => "https",
                },
              )
            )

            middleware = Marten::Middleware::StrictTransportSecurity.new
            response = middleware.call(
              request,
              ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
            )

            response.headers[:"Strict-Transport-Security"].should eq "max-age=31536000; includeSubDomains"
          end
        end
      end
    end

    it "includes the expected header when a max age and is configured and the preload option is used" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("strict_transport_security.preload", true) do
          with_overridden_setting("use_x_forwarded_proto", true) do
            request = Marten::HTTP::Request.new(
              ::HTTP::Request.new(
                method: "GET",
                resource: "/test/xyz",
                headers: HTTP::Headers{
                  "Host"              => "example.com",
                  "X-Forwarded-Proto" => "https",
                },
              )
            )

            middleware = Marten::Middleware::StrictTransportSecurity.new
            response = middleware.call(
              request,
              ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
            )

            response.headers[:"Strict-Transport-Security"].should eq "max-age=31536000; preload"
          end
        end
      end
    end

    it "includes the expected header when a max age, the include_sub_domains, and preload options are set" do
      with_overridden_setting("strict_transport_security.max_age", 31_536_000, nilable: true) do
        with_overridden_setting("strict_transport_security.include_sub_domains", true) do
          with_overridden_setting("strict_transport_security.preload", true) do
            with_overridden_setting("use_x_forwarded_proto", true) do
              request = Marten::HTTP::Request.new(
                ::HTTP::Request.new(
                  method: "GET",
                  resource: "/test/xyz",
                  headers: HTTP::Headers{
                    "Host"              => "example.com",
                    "X-Forwarded-Proto" => "https",
                  },
                )
              )

              middleware = Marten::Middleware::StrictTransportSecurity.new
              response = middleware.call(
                request,
                ->{ Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
              )

              response.headers[:"Strict-Transport-Security"].should eq "max-age=31536000; includeSubDomains; preload"
            end
          end
        end
      end
    end
  end
end
