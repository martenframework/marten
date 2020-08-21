ENV["MARTEN_ENV"] = "test"

require "spec"

require "../src/marten"
require "./test_project"

Spec.before_suite &->Marten.setup
