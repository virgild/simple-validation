require File.join(File.dirname(__FILE__), "spec_helper")

describe SimpleValidation::CheckList do

  before(:all) do    
    @checklist = SimpleValidation.make_checklist do |c|
      c.complain :msg => "A username is required", :on => :username, :as => :username_blank, :when => Proc.new { |bag| bag[:username].blank? }
      c.complain :msg => "A username must be at least 5 characters", :on => :username, :as => :username_minlength, :when => Proc.new { |bag| bag[:username].length < 5 }
      c.depends :username_minlength, :username_blank
      
      c.complain :on => :email do |c|
        c.add :msg => "An e-mail is required", :as => :email_blank, :when => Proc.new { |bag| bag[:email].blank? }
        c.add :msg => "Incorrect e-mail", :as => :email_value, :when => Proc.new { |bag| bag[:email] != "test@local" }
        c.depends :email_value, :email_blank
      end
      
      c.complain :msg => "A password should be provided", :on => :password, :when => Proc.new { |bag| bag[:password].blank? }
      c.complain :msg => "Passwords should match", :when => Proc.new { |bag| bag[:password] != bag[:password_confirmation] }
    end
  end
  
  it "should find check nodes" do
    @checklist.find_check_node(:username_blank).content.tag.should == :username_blank
    @checklist.find_check_node(:email_value).content.tag.should == :email_value
  end
  
  it "should run the checklist and return proper complaints" do
    complaints = @checklist.run(:username => "", :email => "")
    complaints.length.should == 3
    complaints.should include({:about => :username, :message => "A username is required"})
    complaints.should include({:about => :email, :message => "An e-mail is required"})
    complaints.should include({:about => :password, :message => "A password should be provided"})
    
    complaints = @checklist.run(:username => "test", :email => "")
    complaints.length.should == 3
    complaints.should include({:about => :username, :message => "A username must be at least 5 characters"})
    complaints.should include({:about => :email, :message => "An e-mail is required"})
    complaints.should include({:about => :password, :message => "A password should be provided"})
    
    complaints = @checklist.run(:username => "tester", :email => "")
    complaints.length.should == 2
    complaints.should include({:about => :email, :message => "An e-mail is required"})
    complaints.should include({:about => :password, :message => "A password should be provided"})
    
    complaints = @checklist.run(:username => "tester", :email => "not_correct@local")
    complaints.length.should == 2
    complaints.should include({:about => :email, :message => "Incorrect e-mail"})
    complaints.should include({:about => :password, :message => "A password should be provided"})
    
    complaints = @checklist.run(:username => "tester", :email => "test@local")
    complaints.length.should == 1
    complaints.should include({:about => :password, :message => "A password should be provided"})
    
    complaints = @checklist.run(:username => "tester", :email => "test@local", :password => "secret")
    complaints.length.should == 1
    complaints.should include({:about => nil, :message => "Passwords should match"})
    
    complaints = @checklist.run(:username => "tester", :email => "test@local", :password => "secret", :password_confirmation => "not_secret")
    complaints.length.should == 1
    complaints.should include({:about => nil, :message => "Passwords should match"})
    
    complaints = @checklist.run(:username => "tester", :email => "test@local", :password => "secret", :password_confirmation => "secret")
    complaints.length.should == 0
  end
  
  it "should raise exception on cyclic dependencies" do
    checklist = SimpleValidation.make_checklist do |c|
      c.complain :when => Proc.new { |b| b[:name].blank? }, :msg => "Name is required", :as => :name_required, :on => :name
      c.complain :when => Proc.new { |b| b[:name].length < 5 }, :msg => "Name must be at least 5 characters", :as => :name_length, :on => :name
      c.complain :when => Proc.new { |b| b[:name][0] == "!" }, :msg => "Name must not start with exclamation", :as => :name_start, :on => :name
      c.depends :name_length, :name_required
      c.depends :name_start, :name_length
      lambda { c.depends :name_required, :name_start }.should raise_error { |e| e.message.should == "Cannot create cyclic check dependency" }
      lambda { c.depends :name_required, :name_required }.should raise_error { |e| e.message.should == "Cannot depend on self" }
    end
  end

end