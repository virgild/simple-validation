# simple-validation

`simple-validation` is a Ruby library for running a validation checklist on a Hash. 
The checklist receives a bag (`Hash` object) when it is run and returns an `Array` of complaints.
A complaint is a hash that has a `:message` and `:about` that corresponds to the `:msg` and `:on` values.

## Example

    checklist = SimpleValidation.make_checklist do |c|
      c.complain :when => Proc.new { |bag| bag[:username] == "" }, :msg => "A username is required", :on => :username
      c.complain :when => Proc.new { |bag| bag[:email].length < 5 }, :msg => "An e-mail must have at least 5 characters", :on => :email
    end
    
    my_data = { :username => "", :email => "test" }
    complaints = checklist.run(my_data)

### Complaint Dependencies

You can raise a complaint only when another complaint is raised. A complaint can depend on another as 
specified in the following example:
  
    checklist = SimpleValidation.make_checklist do |c|
      c.complain :when => Proc.new { |bag| bag[:username] == "" }, :msg => "A username is required", 
        :on => :username, :as => :username_required
      c.complain :when => Proc.new { |bag| bag[:username].length < 7 }, :msg => "A username must be at least 7 characters", 
        :on => :username, :as => :username_min_length
      c.depends :username_min_length, :username_required
      
      c.complain :when => Proc.new { |bag| bag[:email].length < 5 }, :msg => "An e-mail must have at least 5 characters", :on => :email
    end
  
The complaint tagged as `:username_min_length` is checked only when `:username_required` is true. To specify complaint
dependencies, the `:on` option must be specified.