require "./spec_helper"

describe Auth::SignUpSchema do
  describe "#valid?" do
    it "returns true if the email is valid and the provided passwords are the same" do
      schema = Auth::SignUpSchema.new(
        Marten::HTTP::Params::Data{
          "email"     => ["test@example.com"],
          "password1" => ["insecure"],
          "password2" => ["insecure"],
        }
      )
      schema.valid?.should be_true
      schema.errors.should be_empty
    end

    it "returns false if the data is not provided" do
      schema = Auth::SignUpSchema.new(
        Marten::HTTP::Params::Data{"email" => [""], "password1" => [""], "password2" => [""]}
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 3
      schema.errors[0].field.should eq "email"
      schema.errors[0].type.should eq "required"
      schema.errors[1].field.should eq "password1"
      schema.errors[1].type.should eq "required"
      schema.errors[2].field.should eq "password2"
      schema.errors[2].type.should eq "required"
    end

    it "returns false if the email address is already taken" do
      create_user(email: "test@example.com", password: "insecure")

      schema = Auth::SignUpSchema.new(
        Marten::HTTP::Params::Data{
          "email"     => ["test@example.com"],
          "password1" => ["insecure"],
          "password2" => ["insecure"],
        }
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 1
      schema.errors[0].field.should eq "email"
      schema.errors[0].message.should eq "This email address is already taken"
    end

    it "returns false if the email address is already taken in a case insensitive way" do
      create_user(email: "test@example.com", password: "insecure")

      schema = Auth::SignUpSchema.new(
        Marten::HTTP::Params::Data{
          "email"     => ["TesT@ExamPLE.com"],
          "password1" => ["insecure"],
          "password2" => ["insecure"],
        }
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 1
      schema.errors[0].field.should eq "email"
      schema.errors[0].message.should eq "This email address is already taken"
    end

    it "returns false if the two password values do not match" do
      schema = Auth::SignUpSchema.new(
        Marten::HTTP::Params::Data{
          "email"     => ["test@example.com"],
          "password1" => ["insecure"],
          "password2" => ["other"],
        }
      )

      schema.valid?.should be_false

      schema.errors.size.should eq 1
      schema.errors[0].field.should be_nil
      schema.errors[0].message.should eq "The two password fields do not match"
    end
  end
end
