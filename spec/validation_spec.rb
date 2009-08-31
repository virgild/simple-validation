require File.join(File.dirname(__FILE__), "spec_helper")

describe Validation do

  before(:all) do
    class User
      attr_accessor :username, :email, :id
      def initialize
      end
    end
  end

  it "should build validations" do
    user_validation = Validation.new do |v|
      v.complain "Username should be provided", :about => :username, 
        :when => Proc.new { |subject| subject.username.blank? }
      v.complain "Username should be at least 5 characters", :about => :username, 
        :when => Proc.new { |subject| !subject.username.blank? && subject.username.length < 5 }
    end
    
    user = User.new
    user.username = ""
    
    user_validation.run(user)
    user_validation.should have(1).complaints
    
    complaint = user_validation.complaints[0]
    complaint[:about].should == :username
    complaint[:message].should == "Username should be provided"
  end

end
