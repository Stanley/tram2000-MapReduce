require "rubygems"
require "msgpack"
require "kanar"

STDIN.each_line do |line|
  # Read key-value pairs from standard input
  poly, blips = line.split("\t")
  # Return to stdout the results
  p Kanar.validate(poly, MessagePack.unpack(blips)).to_msgpack
end
