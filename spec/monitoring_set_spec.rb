require 'spec_helper'

describe Graphy::MonitoringSet do
  subject { Graphy::MonitoringSet.new(:memory) }

  it "should have no watches by default" do
    subject.watches.should == []
  end

  describe "#name" do
    it "should return its name as string" do
      subject.name.should == "memory"
    end
  end

  describe "#type" do
    context "if :type option is passed and is a symbol" do
      subject { Graphy::MonitoringSet.new("mem2", :type => :memory) }

      it "should return that option's value" do
        subject.type.should == :memory
      end
    end

    context "if :type option is passed and is a string" do
      subject { Graphy::MonitoringSet.new("mem2", :type => 'memory') }

      it "should return that option's value converted to a symbol" do
        subject.type.should == :memory
      end
    end

    context "if :type option is not passed" do
      subject { Graphy::MonitoringSet.new("cpu") }

      it "should return its name converted to a symbol" do
        subject.type.should == :cpu
      end
    end
  end

  context "if there is a defined monitor matching the set's type" do
    it "should not raise an error in constructor" do
      expect { Graphy::MonitoringSet.new("mem", :type => :memory) }.to_not(raise_error)
    end

    it "should return that monitor in #monitor" do
      set = Graphy::MonitoringSet.new("mem", :type => :memory)
      set.monitor.should == Graphy.monitors[:memory]
    end
  end

  context "if there is no defined monitor matching the set's type" do
    it "should raise an error in constructor" do
      expect { Graphy::MonitoringSet.new("mem", :type => :unicorns) }.to(raise_error)
    end
  end

  describe "#watch" do
    it "should add a watch to its list of watches" do
      subject.watch("Rack", :label => "Rails instances")

      subject.watches.should have(1).element
      subject.watches.first.name.should == "Rack"
      subject.watches.first.options.should == { :label => "Rails instances" }
    end
  end

  context "if its name contains invalid characters" do
    it "should raise an error" do
      ["with space", "symbols$"].each do |name|
        expect { Graphy::MonitoringSet.new(name, :type => :memory) }.to(raise_error)
      end
    end
  end

  context "if its name doesn't contain invalid characters" do
    it "should not raise an error" do
      ["memory", "with-dashes", "with_some_underscores", "with.dots", "number123", "UpPeRcAsE"].each do |name|
        # honestly, the last one shouldn't be a valid name, but the regexp would be too complex ;)
        expect { Graphy::MonitoringSet.new(name, :type => :memory) }.to_not(raise_error)
      end
    end
  end

  describe "#to_json" do
    before :each do
      subject.watch "Rack", :label => "Rails instances"
      subject.watch "nginx"
    end

    it "should return a proper JSON string" do
      string = subject.to_json
      string.should be_a_kind_of(String)
      expect { JSON.parse(string) }.to_not(raise_error)
    end

    describe "parsed" do
      let(:json) { JSON.parse(subject.to_json) }

      it "should contain the set's name" do
        json['name'].should == 'memory'
      end

      it "should contain the unit of set's monitor" do
        json['unit'].should == subject.monitor.unit
      end

      it "should contain the labels of set's watches" do
        json['labels'].should == ['Rails instances', 'nginx']
      end
    end
  end

end
