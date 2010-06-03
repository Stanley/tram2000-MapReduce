require "rubygems"
require "msgpack"
require "kanar"

STDIN.each_line do |line|
  # Read key-value pairs from standard input,
  # where key is encoded polyline and value is Array of corresponding blips
  poly, blips = line.split("\t")
  
  # Return trace to stdout
  p Kanar.validate(poly, MessagePack.unpack(blips)).to_msgpack
end
