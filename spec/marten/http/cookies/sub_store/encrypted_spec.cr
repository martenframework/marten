require "./spec_helper"

describe Marten::HTTP::Cookies::SubStore::Encrypted do
  describe "#fetch" do
    it "allows to retrieve a specific encrypted cookie value using its name" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch("test") { "fallback" }.should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch(:test) { "fallback" }.should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name and a default" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch("test", "fallback").should eq "value"
    end

    it "allows to retrieve a specific cookie value using its name as a symbol and a default" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch(:test, "fallback").should eq "value"
    end

    it "yields the cookie name when not found" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch("unknown") { |n| n }.should eq "unknown"
    end

    it "returns the default value if the cookie name is not found" do
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(Marten::HTTP::Cookies.new)
      sub_store.set("test", "value")
      sub_store.fetch("unknownn", "fallback").should eq "fallback"
    end
  end

  describe "#set" do
    it "allows to set a simple cookie using a cookie name string" do
      cookies = Marten::HTTP::Cookies.new
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)
      sub_store.set("foo", "bar")
      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
    end

    it "allows to set a simple cookie using a cookie name symbol" do
      cookies = Marten::HTTP::Cookies.new
      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)
      sub_store.set(:foo, :bar)
      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
    end

    it "allows to set a simple cookie associated with an expiry time" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      expiry = Time.local + Time::Span.new(hours: 10, minutes: 10, seconds: 10)

      sub_store.set("foo", "bar", expires: expiry)

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].expires.should eq expiry
    end

    it "defaults to no specific expiry for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].expires.should be_nil
    end

    it "allows to set a simple cookie associated with a custom path" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", path: "/path")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].path.should eq "/path"
    end

    it "defaults to the root path for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].path.should eq "/"
    end

    it "allows to set a simple cookie associated with a domain" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", domain: "example.com")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].domain.should eq "example.com"
    end

    it "defaults to no domain for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].domain.should be_nil
    end

    it "allows to set a secure cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", secure: true)

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].secure.should be_true
    end

    it "defaults to non-secure for all cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].secure.should be_false
    end

    it "allows to set a HTTP-only cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", http_only: true)

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].http_only.should be_true
    end

    it "defaults to non HTTP-only cookies" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].http_only.should be_false
    end

    it "allows to set a lax cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", same_site: "lax")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].samesite.not_nil!.lax?.should be_true
    end

    it "allows to set a strict cookie" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar", same_site: :strict)

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].samesite.not_nil!.strict?.should be_true
    end

    it "defaults to cookies without a samesite policy" do
      raw_cookies = ::HTTP::Request.new(method: "GET", resource: "/test/xyz").cookies
      cookies = Marten::HTTP::Cookies.new(raw_cookies)

      sub_store = Marten::HTTP::Cookies::SubStore::Encrypted.new(cookies)

      sub_store.set("foo", "bar")

      cookies["foo"].should_not eq "bar"
      sub_store.fetch("foo").should eq "bar"
      raw_cookies["foo"].samesite.should be_nil
    end
  end
end
