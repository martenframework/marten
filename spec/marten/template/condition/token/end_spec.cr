require "./spec_helper"

describe Marten::Template::Condition::Token::End do
  describe "#eval" do
    it "raises a not implemented error" do
      token = Marten::Template::Condition::Token::End.new
      expect_raises(
        NotImplementedError,
        "End token should not be evaluated"
      ) do
        token.eval(Marten::Template::Context{"foo" => 42})
      end
    end
  end

  describe "#id" do
    it "returns the expected string identifier" do
      token = Marten::Template::Condition::Token::End.new
      token.id.should eq "end"
    end
  end

  describe "#lbp" do
    it "returns the expected left binding power" do
      token = Marten::Template::Condition::Token::End.new
      token.lbp.should eq 0_u8
    end
  end

  describe "#nud" do
    it "raises an invalid syntax error by default" do
      token = Marten::Template::Condition::Token::End.new
      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Unexpected end of expression"
      ) do
        token.nud(Marten::Template::Condition.new(["42", "||", "42"]))
      end
    end
  end
end
