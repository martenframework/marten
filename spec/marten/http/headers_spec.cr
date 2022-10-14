require "./spec_helper"

describe Marten::HTTP::Headers do
  describe "::new" do
    it "allows to initialize a header by specifying standard HTTP::Headers object" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["Content-Type"].should eq "application/json"
    end

    it "allows to initializes an empty headers set" do
      headers = Marten::HTTP::Headers.new
      headers.should be_empty
    end
  end

  describe "#==" do
    it "returns true if the other headers set is the same object" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.should eq headers
    end

    it "returns true if the other headers set corresponds to the same headers" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.should eq Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
    end

    it "returns false if the other headers does not correspond to the same headers" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.should_not eq Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "text/html"})
    end
  end

  describe "#[]" do
    it "allows to retrieve a specific header value using its original name" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["Content-Type"].should eq "application/json"
    end

    it "allows to retrieve a specific header value using its underscore notation" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["CONTENT_TYPE"].should eq "application/json"
      headers["content_type"].should eq "application/json"
    end

    it "allows to retrieve a specific header value using its name as symbol" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers[:"Content-Type"].should eq "application/json"
      headers[:CONTENT_TYPE].should eq "application/json"
      headers[:content_type].should eq "application/json"
    end
  end

  describe "#[]?" do
    it "allows to retrieve a specific header value using its original name" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["Content-Type"]?.should eq "application/json"
    end

    it "allows to retrieve a specific header value using its underscore notation" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["CONTENT_TYPE"]?.should eq "application/json"
      headers["content_type"]?.should eq "application/json"
    end

    it "allows to retrieve a specific header value using its name as symbol" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers[:"Content-Type"]?.should eq "application/json"
      headers[:CONTENT_TYPE]?.should eq "application/json"
      headers[:content_type]?.should eq "application/json"
    end

    it "returns nil if the header is not present" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["X-Foo-Bar"]?.should be_nil
      headers["X_FOO_BAR"]?.should be_nil
      headers["x_foo_bar"]?.should be_nil
      headers[:"X-Foo-Bar"]?.should be_nil
      headers[:X_FOO_BAR]?.should be_nil
      headers[:x_foo_bar]?.should be_nil
    end
  end

  describe "#[]=" do
    it "sets a specific header value from a name string" do
      headers = Marten::HTTP::Headers.new
      headers["Content-Type"] = "text/html"
      headers["Content-Type"].should eq "text/html"
    end

    it "sets a specific header value from a name symbol" do
      headers = Marten::HTTP::Headers.new
      headers[:CONTENT_TYPE] = "text/html"
      headers["Content-Type"].should eq "text/html"
    end
  end

  describe "#delete" do
    it "deletes a header from a header name string and returns the associated value" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.delete("Content-Type").should eq "application/json"
      headers.has_key?("Content-Type").should be_false
    end

    it "deletes a header from a header name symbol and returns the associated value" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.delete(:CONTENT_TYPE).should eq "application/json"
      headers.has_key?(:CONTENT_TYPE).should be_false
    end

    it "returns nil if the header does not exist" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.delete("unknown").should be_nil
    end
  end

  describe "#each" do
    it "allows to iterate over the keys and values" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.each do |key, value|
        key.should eq "Content-Type"
        value.should eq ["application/json"]
      end
    end
  end

  describe "#empty?" do
    it "returns true if no headers are set" do
      headers = Marten::HTTP::Headers.new
      headers.empty?.should be_true
    end

    it "returns false if headers are set" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.empty?.should be_false
    end
  end

  describe "#has_key?" do
    it "returns true if the header is present" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.has_key?("Content-Type").should be_true
      headers.has_key?("CONTENT_TYPE").should be_true
      headers.has_key?("content_type").should be_true
      headers.has_key?(:"Content-Type").should be_true
      headers.has_key?(:CONTENT_TYPE).should be_true
      headers.has_key?(:content_type).should be_true
    end

    it "returns false if the header is not present" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.has_key?("X-Foo-Bar").should be_false
      headers.has_key?("X_FOO_BAR").should be_false
      headers.has_key?("x_foo_bar").should be_false
      headers.has_key?(:"X-Foo-Bar").should be_false
      headers.has_key?(:X_FOO_BAR).should be_false
      headers.has_key?(:x_foo_bar).should be_false
    end
  end

  describe "#fetch" do
    it "allows to retrieve a specific header value using its original name" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch("Content-Type").should eq "application/json"
    end

    it "allows to retrieve a specific header value using its underscore notation" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch("CONTENT_TYPE").should eq "application/json"
      headers.fetch("content_type").should eq "application/json"
    end

    it "allows to retrieve a specific header value using its name as symbol" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch(:"Content-Type").should eq "application/json"
      headers.fetch(:CONTENT_TYPE).should eq "application/json"
      headers.fetch(:content_type).should eq "application/json"
    end

    it "returns nil by default if the header is not present" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch("X-Foo-Bar").should be_nil
      headers.fetch("X_FOO_BAR").should be_nil
      headers.fetch("x_foo_bar").should be_nil
      headers.fetch(:"X-Foo-Bar").should be_nil
      headers.fetch(:X_FOO_BAR).should be_nil
      headers.fetch(:x_foo_bar).should be_nil
    end

    it "returns a specified fallback if the header is not present" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch("X-Foo-Bar", "notset").should eq "notset"
      headers.fetch("X_FOO_BAR", "notset").should eq "notset"
      headers.fetch("x_foo_bar", "notset").should eq "notset"
      headers.fetch(:"X-Foo-Bar", "notset").should eq "notset"
      headers.fetch(:X_FOO_BAR, "notset").should eq "notset"
      headers.fetch(:x_foo_bar, "notset").should eq "notset"
    end

    it "calls the specified block if the passed name is not found" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.fetch("X-Foo-Bar") { |k| "notset: #{k}" }.should eq "notset: X-Foo-Bar"
    end
  end

  describe "#patch_vary" do
    it "allows to add a single header name to the headers" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers.new)
      headers.patch_vary("Cookie")
      headers[:VARY].should eq "Cookie"
    end

    it "allows to add multiple header names to the headers" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers.new)
      headers.patch_vary("Cookie", "Accept-Encoding")
      headers[:VARY].should eq "Cookie, Accept-Encoding"
    end

    it "does not result in duplicated header names in the Vary header" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers.new)
      headers.patch_vary("Cookie", "Accept-Encoding")
      headers.patch_vary("Cookie", "Accept-Encoding")
      headers[:VARY].should eq "Cookie, Accept-Encoding"
    end

    it "is case-insensitive" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers.new)
      headers.patch_vary("Cookie", "Accept-Encoding")
      headers.patch_vary("cookie", "accept-encoding")
      headers[:VARY].should eq "Cookie, Accept-Encoding"
    end
  end

  describe "#size" do
    it "returns the number of headers" do
      headers_0 = Marten::HTTP::Headers.new(HTTP::Headers.new)
      headers_0.size.should eq 0

      headers_1 = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers_1.size.should eq 1

      headers_2 = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json", "X-Foo" => "Bar"})
      headers_2.size.should eq 2
    end
  end
end
