require "./spec_helper"

describe Marten::Core::Validation::Error do
  describe "::new" do
    it "allows to initialize an error from a message and a specific type string" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid")
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should be_nil
    end

    it "allows to initialize an error from a message and a specific type symbol" do
      error = Marten::Core::Validation::Error.new("This is not valid", :invalid)
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should be_nil
    end

    it "allows to initialize an error associated with a specific field string" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should eq "content"
    end

    it "allows to initialize an error associated with a specific field symbol" do
      error = Marten::Core::Validation::Error.new("This is not valid", :invalid, :content)
      error.message.should eq "This is not valid"
      error.type.should eq "invalid"
      error.field.should eq "content"
    end
  end

  describe "#message" do
    it "returns the specified error message" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.message.should eq "This is not valid"
    end
  end

  describe "#type" do
    it "returns the specified error type" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.type.should eq "invalid"
    end
  end

  describe "#field" do
    it "defaults to nil" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid")
      error.field.should be_nil
    end

    it "returns the specified error field" do
      error = Marten::Core::Validation::Error.new("This is not valid", "invalid", "content")
      error.field.should eq "content"
    end
  end
end
