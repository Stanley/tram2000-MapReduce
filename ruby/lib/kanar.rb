require "decoder"
require "segment"

class Kanar

  # Input: polyline and Array of blips
  # Output: Array of footprints
  def self.validate(polyline, blips)
    
    passengers = {} # Hash which remembers how much time has each passenger waited
    
    # Average blip of all blips
    avg = nil
    
    # Calculate waiting time for each user and cut it out
    blips.each do |blip|
    
      # Replace string with array of integers
      bytes = blip.data.each_byte.to_a
      
      # Find minimum
      min = bytes.min
      
      # Save waiting time and cut it out from blip data
      bytes.reverse.each.with_index do |b,i|      
        if b == min
          # Remember how long did the passenger waited in seconds
          passengers[blip.owner] = bytes.size - i

          # Rest doesn't matter
          bytes = bytes[-i..-1]
          break
        end
      end
      
      # Find average blip
      avg = bytes
      
      # Get rid of fake blips 
      
    end
    
    # Convert absolute distance values to array of distances on the path
    # going from end to begining
    steps = Polyline.decode(polyline).reverse # polyline.gsub("\\\\", "\\") 
    avg.reverse!
    
    enum = steps.each_cons(2) # polyline enumerator
    length = 0 # how far we are form stop A in straight line
    dist = 0   # how far is the latest segment from the beginning


    # Calculates footprint (lat-lng pairs)
    footprint = []
    
    # For each second
    avg.each do |m|
      length += m
      
      # Find appropriate segnent
      seg = nil
      while length > dist
        seg = Segment.new enum.next
        dist = beg.to seg.last
      end
      
      # Calculate point of segment in which we are now
      # steps.last stans for location of beginning stop
      seg.intersection *steps.last, length
      
      # TODO: what if null?
                  
    end
    
  end
end
