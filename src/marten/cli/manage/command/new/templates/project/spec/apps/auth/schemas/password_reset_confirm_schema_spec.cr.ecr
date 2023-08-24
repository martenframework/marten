require "./spec_helper"

describe Auth::PasswordResetConfirmSchema do
  describe "#valid?" do
    it "returns true if the two password values are the same" do
      schema = Auth::PasswordResetConfirmSchema.new(
        Marten::HTTP::Params::Data{"password1" => ["insecure"], "password2" => ["insecure"]}
      )
      schema.valid?.should be_true
      schema.errors.should be_empty
    end

    it "returns false if the two password values are not provided" do
      schema = Auth::PasswordResetConfirmSchema.new(
        Marten::HTTP::Params::Data{"password1" => [""], "password2" => [""]}
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 2
      schema.errors[0].field.should eq "password1"
      schema.errors[0].type.should eq "required"
      schema.errors[1].field.should eq "password2"
      schema.errors[1].type.should eq "required"
    end

    it "returns false if the two password values are not the same" do
      schema = Auth::PasswordResetConfirmSchema.new(
        Marten::HTTP::Params::Data{"password1" => ["insecure"], "password2" => ["other"]}
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 1
      schema.errors[0].field.should be_nil
      schema.errors[0].message.should eq "The two password fields do not match"
    end
  end
end
