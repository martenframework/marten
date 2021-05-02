require "./spec_helper"

describe Marten::Template::Condition::Token::Base do
  describe "#eval" do
    it "must be implemented and returns a template value" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      token.eval(Marten::Template::Context{"foo" => 42}).should be_a Marten::Template::Value
      token.eval(Marten::Template::Context{"foo" => 42}).truthy?.should be_true
    end
  end

  describe "#id" do
    it "must be implemented and returns a string identifier" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      token.id.should eq "test"
    end
  end

  describe "#lbp" do
    it "must be implemented and returns a token left binding power" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      token.lbp.should eq 42_u8
    end
  end

  describe "#led" do
    it "raises an invalid syntax error by default" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unexpected 'test' as infix operator"
      ) do
        token.led(
          Marten::Template::Condition.new(["42", "||", "42"]),
          Marten::Template::Condition::Token::BaseSpec::Test.new
        )
      end
    end
  end

  describe "#nud" do
    it "raises an invalid syntax error by default" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unexpected 'test' as prefix operator"
      ) do
        token.nud(Marten::Template::Condition.new(["42", "||", "42"]))
      end
    end
  end

  describe "#to_s" do
    it "returns the string identifier of the token" do
      token = Marten::Template::Condition::Token::BaseSpec::Test.new
      token.to_s.should eq "test"
    end
  end
end

class Marten::Template::Condition::Token::BaseSpec::Test < Marten::Template::Condition::Token::Base
  def eval(context : Context) : Marten::Template::Value
    Marten::Template::Value.from(true)
  end

  def id : String
    "test"
  end

  def lbp : UInt8
    42_u8
  end
end
