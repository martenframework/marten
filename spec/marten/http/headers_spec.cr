require "./spec_helper"

describe Marten::HTTP::Headers do
  describe "::new" do
    it "allows to initialize a header by specifying standard HTTP::Headers object" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers["Content-Type"].should eq "application/json"
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

  describe "#each" do
    it "allows to iterate over the keys and values" do
      headers = Marten::HTTP::Headers.new(HTTP::Headers{"Content-Type" => "application/json"})
      headers.each do |key, value|
        key.should eq "Content-Type"
        value.should eq ["application/json"]
      end
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
