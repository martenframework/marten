require "./spec_helper"

describe String do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'ascii_only?' attribute" do
      "Hello World!".resolve_template_attribute("ascii_only?").should be_true
      "Hello World!🌍".resolve_template_attribute("ascii_only?").should be_false
    end

    it "returns the expected result when requesting the 'blank?' attribute" do
      "".resolve_template_attribute("blank?").should be_true
      "Hello World!".resolve_template_attribute("blank?").should be_false
    end

    it "returns the expected result when requesting the 'bytesize' attribute" do
      "Hello World!".resolve_template_attribute("bytesize").should eq 12
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      "Hello World!".resolve_template_attribute("empty?").should be_false
      "".resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'size' attribute" do
      "Hello World!".resolve_template_attribute("size").should eq 12
    end

    it "returns the expected result when requesting the 'valid_encoding?' attribute" do
      "Hello World!".resolve_template_attribute("valid_encoding?").should be_true
    end
  end
end
