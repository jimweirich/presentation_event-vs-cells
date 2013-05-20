require 'rspec/given'
require 'flexmock/rspec/configure'
require 'messages/cell/line_protocol'

RSpec::Given.use_natural_assertions

describe LineProtocol do
  Given(:sock) { flexmock("Socket") }
  Given(:prot) { LineProtocol.new(sock) }

  describe "#gets" do
    Given { sock.should_receive(:readpartial).and_return(*lines) }

    context "when reading a single line" do
      Given(:lines) { ["one\n"] }
      Then { prot.gets == "one\n" }
    end

    context "when reading a multiple lines" do
      Given(:lines) { ["one\ntwo\nthree\n"] }
      Then {
        [prot.gets, prot.gets, prot.gets] ==
        ["one\n", "two\n", "three\n"]
      }
    end

    context "when reading a multiple lines from multiple packets" do
      Given(:lines) { ["one\ntwo\n", "three\n"] }
      Then {
        [prot.gets, prot.gets, prot.gets] ==
        ["one\n", "two\n", "three\n"]
      }
    end

    context "when reading a multiple lines split across multiple packets" do
      Given(:lines) { ["one\ntw", "o\nthree\n"] }
      Then {
        [prot.gets, prot.gets, prot.gets] ==
        ["one\n", "two\n", "three\n"]
      }
    end
  end

  describe "#puts" do
    Given { sock.should_receive(:write) }
    context "with no newline" do
      When { prot.puts "hi" }
      Then { sock.should have_received(:write).with("hi\n") }
    end
    context "with a newline" do
      When { prot.puts "hi\n" }
      Then { sock.should have_received(:write).with("hi\n") }
    end
  end
end
