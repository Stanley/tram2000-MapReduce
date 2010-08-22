#!/usr/bin/env ruby
# encoding: ascii

$: << File.join(File.dirname(__FILE__), 'lib')
require "rubygems"
require "bundler/setup"
require "json"
require "kanar"

Encoding.default_external = Encoding.find("ASCII-8BIT")

STDIN.each_line do |line|
  # Read key-value pairs from standard input,
  # where key is encoded polyline and value is Array of corresponding blips
  poly, blips = line.split("\t")

  # Return trace to stdout
  print Kanar.validate(poly, JSON.parse(blips).map{|b| Blip.new(b)}).to_json, "\n"
end
