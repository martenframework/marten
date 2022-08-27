require "./spec_helper"

describe Marten::HTTP::Cookies do
  describe "::new" do
    it "allows to initialize a cookies set by specifying a standard HTTP::Cookies object" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies["test"].should eq "value"
    end

    it "allows to initializes an empty cookies set" do
      cookies = Marten::HTTP::Cookies.new
      cookies.should be_empty
    end
  end

  describe "#==" do
    it "returns true if the other cookies set is the same object" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.should eq cookies
    end

    it "returns true if the other cookies set corresponds to the same cookies" do
      raw_request = ::HTTP::Request.new(method: "GET", resource: "/test/xyz")
      raw_request.cookies["test"] = "value"

      cookies = Marten::HTTP::Cookies.new(raw_request.cookies)
      cookies.should eq Marten::HTTP::Cookies.new(raw_request.cookies)
    end

    it "returns false if the other cookies does not correspond to the same cookies" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.should_not eq Marten::HTTP::Cookies.new(HTTP::Cookies{"foo" => "bar"})
    end
  end

  describe "#[]" do
    it "allows to retrieve a specific cookie value using its name" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies["test"].should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies[:test].should eq "value"
    end

    it "raises if the cookie is not found" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      expect_raises(KeyError) { cookies["unknown"] }
    end
  end

  describe "#[]?" do
    it "allows to retrieve a specific cookie value using its name" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies["test"]?.should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies[:test]?.should eq "value"
    end

    it "returns nil if the cookie is not found" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies["unknown"]?.should be_nil
    end
  end

  describe "#[]=" do
    it "sets the passed cookie value with a key string" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies["foo"] = "bar"
      cookies["foo"].should eq "bar"
    end

    it "sets the passed cookie value with a key symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies[:foo] = "bar"
      cookies[:foo].should eq "bar"
    end
  end

  describe "#delete" do
    it "deletes a cookie from a cookie name string and returns the associated value" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.delete("test").should eq "value"
      cookies.has_key?("test").should be_false
    end

    it "deletes a cookie from a cookie name symbol and returns the associated value" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.delete(:test).should eq "value"
      cookies.has_key?(:test).should be_false
    end

    it "returns nil if the cookie does not exist" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.delete("unknown").should be_nil
    end

    it "adds the deleted raw cookie to the cookies to set later on with a passed expiry and a blank value" do
      time = Time.local
      Timecop.freeze(time) do
        cookies = Marten::HTTP::CookiesSpec::Wrapper.new(HTTP::Cookies{"test" => "value"})

        cookies.delete(:test).should eq "value"
        cookies.has_key?(:test).should be_false

        cookies.set_cookies[0].name.should eq "test"
        cookies.set_cookies[0].expires.should eq 1.year.ago
        cookies.set_cookies[0].value.should eq ""
      end
    end
  end

  describe "#each" do
    it "allows to iterate over the keys and values" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.each do |key, value|
        key.should eq "test"
        value.should eq "value"
      end
    end
  end

  describe "#empty?" do
    it "returns true if the cookies set is empty" do
      cookies = Marten::HTTP::Cookies.new
      cookies.empty?.should be_true
    end

    it "returns false if the cookies set is not empty" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.empty?.should be_false
    end
  end

  describe "#encrypted" do
    it "returns the encrypted cookies sub store" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.encrypted.should be_a Marten::HTTP::Cookies::SubStore::Encrypted

      cookies.encrypted.set("foo", "bar", same_site: :strict)

      cookies["foo"].should_not eq "bar"
      cookies.encrypted["foo"].should eq "bar"
    end
  end

  describe "#fetch" do
    it "allows to retrieve a specific cookie value using its name" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch("test") { "fallback" }.should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch(:test) { "fallback" }.should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name and a default" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch("test", "fallback").should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol and a default" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch(:test, "fallback").should eq "value"
    end

    it "yields the cookie name when not found" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch("unknown") { |n| n }.should eq "unknown"
    end

    it "returns the default value if the cookie name is not found" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.fetch("unknownn", "fallback").should eq "fallback"
    end
  end

  describe "#has_key?" do
    it "returns true if the cookie is present for a cookie name string" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.has_key?("test").should be_true
    end

    it "returns true if the cookie is present for a cookie name symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.has_key?("test").should be_true
    end

    it "returns false if the cookie is not present for a cookie name string" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.has_key?("unknown").should be_false
    end

    it "returns false if the cookie is not present for a cookie name symbol" do
      cookies = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies.has_key?("unknown").should be_false
    end
  end

  describe "#set" do
    it "allows to set a simple cookie using a cookie name string" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set("foo", "bar")
      cookies["foo"].should eq "bar"
    end

    it "allows to set a simple cookie using a cookie name symbol" do
      cookies = Marten::HTTP::Cookies.new
      cookies.set(:foo, :bar)
      cookies["foo"].should eq "bar"
    end

    it "allows to set a simple cookie associated with an expiry time" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      expiry = Time.local + Time::Span.new(hours: 10, minutes: 10, seconds: 10)

      cookies.set("foo", "bar", expires: expiry)

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].expires.should eq expiry
    end

    it "defaults to no specific expiry for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].expires.should be_nil
    end

    it "allows to set a simple cookie associated with a custom path" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", path: "/path")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].path.should eq "/path"
    end

    it "defaults to the root path for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].path.should eq "/"
    end

    it "allows to set a simple cookie associated with a domain" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", domain: "example.com")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].domain.should eq "example.com"
    end

    it "defaults to no domain for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].domain.should be_nil
    end

    it "allows to set a secure cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", secure: true)

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].secure.should be_true
    end

    it "defaults to non-secure for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].secure.should be_false
    end

    it "allows to set a HTTP-only cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", http_only: true)

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].http_only.should be_true
    end

    it "defaults to non HTTP-only cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].http_only.should be_false
    end

    it "allows to set a lax cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", same_site: "lax")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].samesite.not_nil!.lax?.should be_true
    end

    it "allows to set a strict cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar", same_site: :strict)

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].samesite.not_nil!.strict?.should be_true
    end

    it "defaults to cookies without a samesite policy" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.set("foo", "bar")

      cookies["foo"].should eq "bar"
      raw_cookies["foo"].samesite.should be_nil
    end
  end

  describe "#signed" do
    it "returns the signed cookies sub store" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      cookies.signed.should be_a Marten::HTTP::Cookies::SubStore::Signed

      cookies.signed.set("foo", "bar", same_site: :strict)

      cookies["foo"].should_not eq "bar"
      cookies.signed["foo"].should eq "bar"
    end
  end

  describe "#size" do
    it "returns the size of the cookies set" do
      cookies_1 = Marten::HTTP::Cookies.new
      cookies_1.size.should eq 0

      cookies_2 = Marten::HTTP::Cookies.new(HTTP::Cookies{"test" => "value"})
      cookies_2.size.should eq 1

      cookies_3 = Marten::HTTP::Cookies.new(HTTP::Cookies{"c1" => "v1", "c2" => "v2"})
      cookies_3.size.should eq 2
    end
  end
end

module Marten::HTTP::CookiesSpec
  class Wrapper < Marten::HTTP::Cookies
    getter set_cookies
  end
end
