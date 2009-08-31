require File.join(File.dirname(__FILE__), "spec_helper")

describe Validation do

  before(:all) do
    class User
      attr_accessor :username, :email, :id
      def initialize
      end
    end
    
    @user_validation = Validation.new do |v|
      v.complain "Username should be provided", :about => :username, :as => :username_not_blank, :when => Proc.new { |s| s.username.blank? }
      v.complain "Username should be at least 5 characters", :about => :username, :as => :username_min_length, :when => Proc.new { |s| s.username.length < 5 }
      v.complain "E-mail should be provided", :about => :email, :as => :email_not_blank, :when => Proc.new { |s| s.email.blank? }
      v.complain "E-mail should end with @local", :about => :email, :as => :email_domain, :when => Proc.new { |s| s.email.grep(/\@local$/).length == 0 }
      v.depends(:username_min_length, :username_not_blank)
      v.depends(:email_domain, :email_not_blank)
    end
  end

  it "find nodes" do
    @user_validation.find_check_node(:email_not_blank).name.should == :email_not_blank    
  end
  
  it "should be constructed" do
    @user_validation.checks.should have(2).children
    @user_validation.checks[:username_not_blank].should have(1).children
    @user_validation.checks[:username_not_blank][:username_min_length].should_not be_nil
    @user_validation.checks[:email_not_blank].should have(1).children
    @user_validation.checks[:email_not_blank][:email_domain].should_not be_nil
  end
  
  it "should validate object" do
    user = User.new
    
    result = @user_validation.run(user)
    result.length.should == 2
    result[0][:about].should == :username
    result[0][:message].should == "Username should be provided"
    result[1][:about].should == :email
    result[1][:message].should == "E-mail should be provided"
    
    user.username = "test"
    result = @user_validation.run(user)
    result.length.should == 2
    result[0][:about].should == :username
    result[0][:message].should == "Username should be at least 5 characters"
    result[1][:about].should == :email
    result[1][:message].should == "E-mail should be provided"
    
    user.username = "tester"
    result = @user_validation.run(user)
    result.length.should == 1
    result[0][:about].should == :email
    result[0][:message].should == "E-mail should be provided"
    
    user.email = "wrong@email.com"
    result = @user_validation.run(user)
    result.length.should == 1
    
    user.email = "tester@local"
    result = @user_validation.run(user)
    result.length.should == 0
  end

end
