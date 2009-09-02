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
  
  class Validation
    attr_reader :checks

    def initialize(&block)
      @checks = Tree::TreeNode.new(:root)
      block.call(self) if block
    end

    # Adds a property check
    def complain(message, options)
      spec = { :message => message, :as => options[:as], :about => options[:about], :inspector => options[:when] }
      @checks << Tree::TreeNode.new(options[:as], spec)
      self
    end

    # Makes a check depend on another one
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

    # Run the validation against an object
    def run(subject)
      complaints = Array.new
      @checks.children.each do |node|
        complaints << run_node(node, subject)
      end

      complaints.flatten
    end

    def find_check_node(name)
      @checks.find { |node| node.name == name }
    end

    private

    def run_node(check_node, subject)
      check = check_node.content
      complaints = Array.new

      if check[:inspector].call(subject)
        complaints << { :message => check[:message], :about => check[:about] }
      else
        check_node.children.each do |node|
          complaints << run_node(node, subject)
        end
      end

      complaints.flatten
    end

  end #class Validation
end #module SimpleValidation
