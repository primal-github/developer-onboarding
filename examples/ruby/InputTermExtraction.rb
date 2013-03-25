#!/usr/bin/env ruby

# Load in the Alchemy API wrapper class
require './AlchemyAPIWrapper.rb'

# Construct our helper with a specific Alchemy API key
$termExtraction = InputTermExtraction.new("<alchemy api key here>")

while true
  # Grab user input
  puts 'Enter URL of a Web page or some text to process, or "quit" to exit:'
  input = gets().chomp()
  if input == "quit" or input == "exit"
    break
  end
  puts

  # Generate the Primal request from the input
  primalRequest = $termExtraction.getPrimalRequest(input)

  # Display it
  if primalRequest != nil
    puts
    puts "Your interests can be found at:"
    puts "  http://primal.com#{primalRequest}"
    puts
  end
end
