require 'extlib'

class Validation
  attr_reader :checks, :complaints
  
  def initialize(&block)
    @checks = Array.new
    @complaints = Array.new
    yield self
  end
  
  def complain(message, options)
    @checks << { 
      :message => message, 
      :when => options[:when],
      :about => options[:about]
    }
  end
  
  def run(subject)
    @complaints.clear
    @checks.each do |check|
      proc = check[:when]
      if proc.call(subject)
        @complaints << {
          :about => check[:about],
          :message => check[:message]
        }
      end
    end
  end

end
