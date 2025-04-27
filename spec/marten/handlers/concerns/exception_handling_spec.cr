require "./spec_helper"

describe Marten::Handlers::ExceptionHandling do
  describe "::rescue_from" do
    it "allows to register a single exception handler with a block" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::SingleBlockExceptionHandler.new

      result = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new
      end

      result.should be_a Marten::HTTP::Response::NotFound
      result.try(&.content).should eq "Not found"
    end

    it "allows to register a single exception handler with a method name" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::SingleMethodExceptionHandler.new

      result = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new
      end

      result.should be_a Marten::HTTP::Response::NotFound
      result.try(&.content).should eq "Not found"
    end

    it "allows to register a single exception handler with multiple exceptions" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::MultipleExceptionsInSingleHandler.new

      result_1 = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new
      end

      result_1.should be_a Marten::HTTP::Response::NotFound
      result_1.try(&.content).should eq "Not found"

      result_2 = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::AnotherDummyError.new
      end

      result_2.should be_a Marten::HTTP::Response::NotFound
      result_2.try(&.content).should eq "Not found"
    end
  end

  describe "#handle_exception" do
    it "runs the right exception handler based on the error type" do
      obj_1 = Marten::Handlers::Concerns::ExceptionHandlingSpec::MultipleExceptionHandlers.new
      obj_1.with_exception_handling { raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new }
      obj_1.dummy_error_handled?.should be_true
      obj_1.another_dummy_error_handled?.should be_false

      obj_2 = Marten::Handlers::Concerns::ExceptionHandlingSpec::MultipleExceptionHandlers.new
      obj_2.with_exception_handling { raise Marten::Handlers::Concerns::ExceptionHandlingSpec::AnotherDummyError.new }
      obj_2.dummy_error_handled?.should be_false
      obj_2.another_dummy_error_handled?.should be_true
    end

    it "always uses the last registered exception handler" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::DuplicatedExceptionHandlers.new

      result = obj.with_exception_handling { raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new }

      result.should be_a Marten::HTTP::Response::NotFound
      result.try(&.content).should eq "Not found"

      obj.dummy_error_handled_1?.should be_false
      obj.dummy_error_handled_2?.should be_true
    end

    it "runs the inherited exception handlers of a parent class" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::Child.new

      result = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::DummyError.new
      end

      result.should be_a Marten::HTTP::Response::NotFound
      result.try(&.content).should eq "Not found"

      obj.dummy_error_handled?.should be_true
      obj.another_dummy_error_handled?.should be_false
    end

    it "runs the exception handlers of a child class" do
      obj = Marten::Handlers::Concerns::ExceptionHandlingSpec::Child.new

      result = obj.with_exception_handling do
        raise Marten::Handlers::Concerns::ExceptionHandlingSpec::AnotherDummyError.new
      end

      result.should be_a Marten::HTTP::Response::NotFound
      result.try(&.content).should eq "Not found"

      obj.dummy_error_handled?.should be_false
      obj.another_dummy_error_handled?.should be_true
    end
  end
end

module Marten::Handlers::Concerns::ExceptionHandlingSpec
  class DummyError < Exception; end

  class AnotherDummyError < Exception; end

  class Base
    include Marten::Handlers::ExceptionHandling

    def with_exception_handling(&)
      yield
    rescue error
      handle_exception(error)
    end
  end

  class SingleBlockExceptionHandler < Base
    rescue_from DummyError do
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class SingleMethodExceptionHandler < Base
    rescue_from DummyError, with: :handle_dummy_error

    private def handle_dummy_error
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class MultipleExceptionHandlers < Base
    rescue_from DummyError, with: :handle_dummy_error
    rescue_from AnotherDummyError, with: :handle_another_dummy_error

    property? dummy_error_handled : Bool = false
    property? another_dummy_error_handled : Bool = false

    private def handle_dummy_error
      self.dummy_error_handled = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end

    private def handle_another_dummy_error
      self.another_dummy_error_handled = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class MultipleExceptionsInSingleHandler < Base
    rescue_from DummyError, AnotherDummyError do
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class DuplicatedExceptionHandlers < Base
    rescue_from DummyError, with: :handle_dummy_error_1
    rescue_from DummyError, with: :handle_dummy_error_2

    property? dummy_error_handled_1 : Bool = false
    property? dummy_error_handled_2 : Bool = false

    private def handle_dummy_error_1
      self.dummy_error_handled_1 = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end

    private def handle_dummy_error_2
      self.dummy_error_handled_2 = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class Parent < Base
    rescue_from DummyError, with: :handle_dummy_error

    property? dummy_error_handled : Bool = false

    private def handle_dummy_error
      self.dummy_error_handled = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end

  class Child < Parent
    rescue_from AnotherDummyError, with: :handle_another_dummy_error

    property? another_dummy_error_handled : Bool = false

    private def handle_another_dummy_error
      self.another_dummy_error_handled = true
      Marten::HTTP::Response::NotFound.new("Not found")
    end
  end
end
