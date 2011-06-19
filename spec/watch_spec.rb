require 'spec_helper'

describe Graphy::Watch do
  subject { Graphy::Watch.new("Rack", :label => "Rails instances") }

  it "should remember its name" do
    subject.name.should == "Rack"
  end

  context "when it has a :label option" do
    it "should return that option's value as its label" do
      subject.label.should == "Rails instances"
    end

    context "when the label is a symbol" do
      subject { Graphy::Watch.new("Rack", :label => :rails) }

      it "should return label as string" do
        subject.label.should == "rails"
      end
    end
  end

  context "when it doesn't have a :label option" do
    subject { Graphy::Watch.new("nginx") }

    it "should return its name as its label" do
      subject.label.should == "nginx"
    end
  end
end