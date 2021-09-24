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
      cookies.fetch("unknownn") { "fallback" }.should eq "fallback"
    end

    it "returns the defaykt value if the cookie name is not found" do
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
