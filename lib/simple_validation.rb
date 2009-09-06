begin
  require 'extlib'
rescue LoadError
  $stderr.puts "simple-validation requires the extlib library"
end

begin
  require 'tree'
rescue LoadError
  $stderr.puts "simple-validation requires the rubytree library"
end

module SimpleValidation
  
  class StructureException < Exception
  end
  
  class CheckList
    attr_reader :checks
    
    def initialize
      @checks = Tree::TreeNode.new(:root)
      @check_index = 0
    end
    
    def complain(options, &block)
      message = options[:msg]
      tag = options[:as] || "check_#{@check_index}".to_sym
      subject = options[:on]
      inspector = options[:when]
      
      if message # straight complain  
        check = Check.new(message, inspector, tag, subject)
        @checks << Tree::TreeNode.new(tag, check)
        @check_index += 1
      else # grouped complain
        @current_subject = subject
        block.call(self)
      end
    end
    
    def add(options)
      message = options[:msg]
      inspector = options[:when]
      tag = options[:as] || "check_#{@check_index}".to_sym
      subject = @current_subject
      check = Check.new(message, inspector, tag, subject)
      @checks << Tree::TreeNode.new(tag, check)
      @check_index += 1
    end
    
    def find_check_node(tag)
      @checks.find { |node| node.name == tag }
    end
    
    def depends(dependent_check, parent_check)
      raise StructureException.new("Cannot depend on self") if dependent_check == parent_check
      
      dependent_node = find_check_node(dependent_check)
      parent_node = find_check_node(parent_check)
      
      if parent_node.parentage.map { |node| node.name }.include?(dependent_check)
        raise StructureException.new("Cannot create cyclic check dependency")
      end
      
      dependent_node.removeFromParent!
      parent_node << dependent_node
    end
    
    def run(bag)
      complaints = Array.new
      @checks.children.each do |node|
        complaints << run_node(node, bag)
      end

      complaints.flatten
    end
    
    def run_node(check_node, bag)
      check = check_node.content
      complaints = Array.new

      if check.inspector.call(bag)
        complaints << { :message => check.message, :about => check.subject }
      else
        check_node.children.each do |node|
          complaints << run_node(node, bag)
        end
      end

      complaints.flatten
    end
    private :run_node
  end
  
  class Check
    attr_reader :message, :tag, :subject, :inspector
    def initialize(message, inspector, tag=nil, subject=nil)
      @tag = tag
      @message = message
      @inspector = inspector
      @subject = subject
    end
  end
  
  module ClassMethods
    def make_checklist(&block)
      checklist = CheckList.new
      block.call(checklist)
      checklist
    end
  end
  
  class << self
    include ClassMethods
  end
  
end #module SimpleValidation
