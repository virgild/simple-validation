require 'extlib'

begin
  require 'tree'
rescue LoadError
  $stderr.puts "Validation requires the rubytree library"
end

class Validation
  attr_reader :checks
  
  def initialize(&block)
    @checks = Tree::TreeNode.new(:root)
    block.call(self) if block
  end
  
  def complain(message, options)
    spec = { :message => message, :as => options[:as], :about => options[:about], :inspector => options[:when] }
    @checks << Tree::TreeNode.new(options[:as], spec)
    self
  end
  
  def depends(dependent_check, parent_check)
    dependent_node = find_check_node(dependent_check)
    parent_node = find_check_node(parent_check)
    dependent_node.removeFromParent!
    parent_node << dependent_node
  end
  
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
  
end