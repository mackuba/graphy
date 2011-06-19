require 'spec_helper'

describe Graphy::Monitor do
  let(:name) { "data_size" }
  let(:unit) { "MB" }
  let(:handler) { mock }

  subject { Graphy::Monitor.new(name, unit, lambda { |a, b| handler.execute(a, b) }) }

  it "should remember its name" do
    subject.name.should == name
  end

  it "should remember its unit" do
    subject.unit.should == unit
  end

  it "should call its block when requested" do
    handler.expects(:execute).with(:watch, :set).once

    subject.call(:watch, :set)
  end
end
