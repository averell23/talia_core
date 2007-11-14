# Create the commands for the Talia console
require 'console_commands'

desc "Show help on the talia console commands"
command(:chelp) do
  puts "Talia console commands:\n\n"
  @commands.each do |command|
    puts "#{command[0]}\t- #{command[1]}"
  end
 nil
end

desc "Print all source URIs"
command(:sources) do
  TaliaCore::Source.find(:all).each do |source|
    puts source.uri
  end
  nil
end

desc "Find a source by local uri"
command(:src) do |uri|
  TaliaCore::Source.find(N::LOCAL + uri)
end

desc "Add a RDF source. Result set to 'adapter'. Use: :type, option => ..."
command(:rdf_source) do |type, options|
  options[:type] = type
  to_var :adapter, ConnectionPool.add_data_source(options)
end

desc "Drop RDF data sources."
command(:rdf_down) do
  ConnectionPool.clear
end

desc "Create a RDFS::Resource. Result set to 'res'"
command(:resource) do |uri|
  to_var :res, RDFS::Resource.new(uri)
end

desc "Show the given element"
command(:show) do |element|
  puts element.class
  if(element.kind_of?(TaliaCore::Source))
    puts "Source: #{element.uri}"
    puts "Name:   #{element.name}m"
    element.direct_predicates.each do |pred|
      puts "#{pred.to_name_s}:"
      pred.each { |val| puts val}
    end
  elsif(element.kind_of?(RDFS::Resource))
    puts "RDFS::Resource #{element.uri}"
    element.direct_predicates.each do |pred|
      puts "#{pred.uri}:"
      element[pred.uri].each { |val| puts "\t#{Uri.new(val).to_name_s}\n\n" }
    end
  else
    puts "Unknown type: #{element.class}"
  end
  nil
end
