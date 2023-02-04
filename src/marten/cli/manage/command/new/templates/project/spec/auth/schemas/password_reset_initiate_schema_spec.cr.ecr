require "./spec_helper"

describe Auth::PasswordResetInitiateSchema do
  describe "#valid?" do
    it "returns true if the email address is provided" do
      schema = Auth::PasswordResetInitiateSchema.new(
        Marten::HTTP::Params::Data{"email" => ["test@example.com"]}
      )
      schema.valid?.should be_true
      schema.errors.should be_empty
    end

    it "returns false if the email address is not provided" do
      schema = Auth::PasswordResetInitiateSchema.new(
        Marten::HTTP::Params::Data{"email" => [""]}
      )
      schema.valid?.should be_false
      schema.errors.size.should eq 1
      schema.errors[0].field.should eq "email"
      schema.errors[0].type.should eq "required"
    end
  end
end
