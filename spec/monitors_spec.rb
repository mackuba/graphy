require 'spec_helper'

describe "Graphy.monitors" do
  it "should define a monitors hash" do
    Graphy.monitors.should be_a(Hash)
  end

  describe "memory monitor" do
    let(:ps_output) { %(
        1080 /sbin/init
      108112 Rack: /var/www/myapp/current
         352 upstart-udev-bridge --daemon
       89504 Rack: /var/www/myapp/current
         872 nginx: master process /usr/local/nginx/sbin/nginx
        3240 nginx: worker process
        1704 PassengerNginxHelperServer /usr/local/rvm/gems/ruby-1.9.2/gems/passenger-2.2
    )}

    def result_for(process)
      watch = stub(:name => process)
      Graphy.expects(:`).with("ps ax -o rss,command").returns(ps_output)
      Graphy.monitors[:memory].call(watch, nil)
    end

    it "should be defined" do
      Graphy.monitors[:memory].should be_a(Graphy::Monitor)
    end

    it "should sum amount of used memory from all matching lines" do
      result_for("Rack").should == "197.6"  # (108112 + 89504) KB to MB
    end

    it "should compare strings case-sensitively" do
      result_for("nginx").should == "4.1"  # (872 + 3240) KB to MB
    end

    it "should match fragments of words or paths" do
      result_for("in").should == "6.9"  # (1080 + 872 + 3240 + 1704) KB to MB
    end
  end

  describe "cpu monitor" do
    let(:ps_output) { %(
       0.0 /sbin/init
       2.9 Rack: /var/www/ruby/current
       0.3 upstart-udev-bridge --daemon
       1.7 Rack: /var/www/ruby/current
       0.1 nginx: master process /usr/local/nginx/sbin/nginx
       0.2 nginx: worker process
      27.5 /usr/bin/mongod --config /etc/mongodb.conf
       0.4 PassengerNginxHelperServer /usr/local/rvm/gems/ruby-1.9.2/gems/passenger-2.2
    )}

    def result_for(process)
      watch = stub(:name => process)
      Graphy.expects(:`).with("ps ax -o pcpu,command").returns(ps_output)
      Graphy.monitors[:cpu].call(watch, nil)
    end

    it "should be defined" do
      Graphy.monitors[:cpu].should be_a(Graphy::Monitor)
    end

    it "should sum amount of used CPU from all matching lines" do
      result_for("Rack").should == "4.6"  # 2.9 + 1.7
    end

    it "should compare strings case-sensitively" do
      result_for("nginx").should == "0.3"  # 0.1 + 0.2
    end

    it "should match fragments of words or paths" do
      result_for("ng").should == "28.2"  # 0.1 + 0.2 + 27.5 + 0.4
    end

    it "should print numbers as integers if the fraction part is equal to 0" do
      result_for("/ruby").should == "5"  # 2.9 + 1.7 + 0.4
    end
  end
end

