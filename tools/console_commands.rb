# This adds the console commands for the talia console

# Array with command descriptions
@commands = Array.new

# Set a command description
def self.desc(description)
  @desc = description
end
  
# Add a new console command
def self.command(command, &command_block)
  # Add the description
  description = @desc ? @desc : "Generic command: #{command}"
  @desc = nil
  @commands << [command.to_s, description]
  
  command = command.to_sym

  (class << self; self; end).class_eval do
    define_method(command, command_block)
  end
end
  

