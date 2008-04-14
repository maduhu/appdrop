require File.dirname(__FILE__) + '/../spec_helper'

describe App do
  before(:each) do
    @app = App.new :port => 3100, :key => 'myapp', :user_id => 3
  end

  it "should be valid" do
    @app.should be_valid
  end
end

describe App, "on create" do
  fixtures :apps
  it "should set the port to the next port" do
    a = App.create :key => 'thisapp', :user_id => 5
    a.should be_valid
    a.created_at.should_not be_nil
    a.port.should == 3001
  end
end

describe App, "update_code with a matching tarfile" do
  fixtures :apps
  before(:each) do
    raise "OMFG don't run me on the production server!" if (/nginx/.match `ls /etc/nginx`)
    `rm /etc/nginx/sites-enabled/*`
    `rm -rf /var/apps/*`
    @app = App.create! :key => 'guestbook', :user_id => 5
    `echo 'junk' > /var/apps/guestbook/app/app.yaml`
    @tarfile = "#{RAILS_ROOT}/spec/fixtures/guestbook.tar.gz"
  end
  it "should have setup" do
    ls = `ls /var/apps/guestbook`
    ls.should match(/tmpapp/)
    appf = `ls /var/apps/guestbook/app`
    appf.should match(/app.yaml/)
  end
  it "should untar the tarball to the tmpapp directory" do
    @app.stub!(:replace_app_with_new)
    @app.update_code @tarfile
    File.exists?("#{App::APP_ROOT}/guestbook/tmpapp/app.yaml").should be_true
  end
  it "should copy the new dir over the old directory" do
    @app.update_code @tarfile
    IO.readlines("#{App::APP_ROOT}/guestbook/app/app.yaml")[0].should match(/guestbook/)
  end
  it "should ensure that it is running"
end

describe App, "update_code with a mismatched tarfile" do
  before(:each) do
    raise "OMFG don't run me on the production server!" if (/nginx/.match `ls /etc/nginx`)
    `rm /etc/nginx/sites-enabled/*`
    `rm -rf /var/apps/*`
    @app = App.create! :key => 'notguestbook', :user_id => 5
    @tarfile = "#{RAILS_ROOT}/spec/fixtures/guestbook.tar.gz"
  end
  it "should fail" do
    lambda{@app.update_code @tarfile}.should raise_error(App::FileError)
  end
end

describe App, "initializing configuration" do
  before(:each) do
    raise "OMFG don't run me on the production server!" if (/nginx/.match `ls /etc/nginx`)
    `rm /etc/nginx/sites-enabled/*`
    `rm -rf /var/apps/*`
    @app = App.new :port => 3100, :key => 'myapp', :user_id => 3
  end
  it "should create the config file" do
    @app.initialize_configuration
    x = `cat /etc/nginx/sites-enabled/myapp`
    x.should match(/3100/)
  end
  it "should create the app directories" do
    @app.initialize_configuration
    ls = `ls /var/apps/myapp`
    ls.should match(/log/)
    ls.should match(/data/)
    ls.should match(/app/)
    ls.should match(/tmpapp/)
  end
  it "should set a portfile" do
    @app.initialize_configuration
    lines = IO.readlines("/var/apps/myapp/portfile")
    lines[0].should == '3100'
  end
end