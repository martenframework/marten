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

  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'ascii_only?' attribute" do
      str_1 = Marten::Template::SafeString.new("Hello World!")
      str_2 = Marten::Template::SafeString.new("Hello World!🌍")
      str_1.resolve_template_attribute("ascii_only?").should be_true
      str_2.resolve_template_attribute("ascii_only?").should be_false
    end

    it "returns the expected result when requesting the 'blank?' attribute" do
      str_1 = Marten::Template::SafeString.new("")
      str_2 = Marten::Template::SafeString.new("Hello World!")
      str_1.resolve_template_attribute("blank?").should be_true
      str_2.resolve_template_attribute("blank?").should be_false
    end

    it "returns the expected result when requesting the 'bytesize' attribute" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.resolve_template_attribute("bytesize").should eq 12
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      str_1 = Marten::Template::SafeString.new("Hello World!")
      str_2 = Marten::Template::SafeString.new("")
      str_1.resolve_template_attribute("empty?").should be_false
      str_2.resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'size' attribute" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.resolve_template_attribute("size").should eq 12
    end

    it "returns the expected result when requesting the 'valid_encoding?' attribute" do
      str = Marten::Template::SafeString.new("Hello World!")
      str.resolve_template_attribute("valid_encoding?").should be_true
    end
  end
end
