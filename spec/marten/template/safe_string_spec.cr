require "./spec_helper"

describe Marten::Template::SafeString do
  it "forward missing methods to the underlying string" do
    str = Marten::Template::SafeString.new("Hello World!")
    str.upcase.should eq "HELLO WORLD!"
    str.downcase.should eq "hello world!"
  end

  describe "#to_s" do
    it "returns the underlying string" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.to_s.should eq "Hello World!"
    end
  end

  describe "#==" do
    it "returns true if the other object is the same string" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.should eq "Hello World!"
    end

    it "returns false if the other object is not the same string" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.should_not eq "Other"
    end
  end
end
