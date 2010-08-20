$: << File.join(File.dirname(__FILE__))
require 'googlemaps_polyline/decoder'
require 'stringio'
require 'segment'
require 'blip'

# This class is responsible for validating input data
class Kanar

  # Input: polyline and Array of blips
  # Output: trace
  # Trace is a Hash with following properties:
  # * polyline_id - id of polyline connecting two stops: A and B
  # * time - time when vehicle left stop A
  # * commuters - Hash of users who send valid blips. Keys are seconds spend waiting on the stop
  # * polluters - Array of users who send rubbish
  # * points - Array of coordinates: [lat, lng]. One pair per second.
  def self.validate(polyline, blips)
    @blips = blips
    # Output value
    trace = {}

    # Check departure time and trip time for each blip
    departure_times = []
    trip_times = []

    @blips.each do |blip|
      sum = 0
      acc = blip.decode.map do |byte|
        sum += byte
      end

      min = acc.min
      cut_acc = acc.reverse.take_while{|b| b != min}
      waited = acc.size - cut_acc.size

      # Waiting time + trip time
      blip['split'] = [waited, cut_acc.size]
      # Remember accumulates distances
      blip['acc'] = cut_acc

      departure_times << blip['time'] + waited
      trip_times << cut_acc.size
    end

    # Find departure time
    departure_times.sort!
    prev = nil
    trace['time'] = departure_times.inject({}) do |hash,time|
      # Maximum difference is 10 sec
      if prev && prev+10 >= time
        hash[prev] += 1
      else
        hash[time] = 1
        prev = time
      end
      hash
    end.max{|x,y| x[1] <=> y[1]}.first.to_i

    # Find time trip took
    trip_times.sort!
    prev = nil
    trip_time = trip_times.inject({}) do |hash,seconds|
      # Maximum difference is 10%
      if prev && prev*1.1 >= seconds
        hash[prev] += 1
      else
        hash[seconds] = 1
        prev = seconds
      end
      hash
    end.max{|x,y| x[1] <=> y[1]}.first

    trace['commuters'] = {}
    trace['polluters'] = []

    trace['polyline_id'], encoded_polyline = polyline.split(":")
    decoder = GoogleMapsPolyline::Decoder
    steps = decoder.new(StringIO.new(encoded_polyline.gsub("\\\\", "\\"))).decode_points.map{|pair| pair.map{|l| l/100_000.0}}
    # TODO: upewnić się co do kierunku odcinka
    total_distance = Segment.length(steps.first, steps.last)

    # Eliminate blips which have:
    # - trip time significantly different than others
    # - departed in different time
    # - made distance which doesn't fit to the polyline
    @blips.each do |blip|
      time_delta = trip_time*0.05
      dist_delta = total_distance*0.05
      if (trip_time - blip['split'][1]).abs < time_delta and
         (trace['time'] - blip['time'].to_i - blip['split'][0]).abs < 10 and
         (total_distance - blip['acc'].first).abs < dist_delta
        # Measurement is considered correct. Remember waiting time.
        trace['commuters'][blip['user']] = blip['split'][0]
      else
        trace['polluters'] << blip['user']
      end
    end

    # Average blip (without fake ones)
    mean = []
    denominator = 0
    @blips.each do |blip|
      if trace['commuters'].keys.include? blip['user']
        denominator += 1
        blip['acc'].each_with_index do |dist, i|
          mean[i] ||= 0
          mean[i] += dist
        end
      end
    end

    # Convert absolute distance values to array of relative distances to the path
    trace['points'] = []
    enum = steps.reverse.each_cons(2)     # polyline enumerator, gives each segment in the path going from B to A
    segment = Segment.new( *enum.next )   # current segment
    segment_range = (Segment.length(steps.first, segment.last))..total_distance

    # For each second give me distance (dist_b) from stop B
    mean.map{|x| x/denominator}.each do |distance|
      begin
        # Find appropriate segment
        while not segment_range.include? distance do
          segment = Segment.new *enum.next
          segment_range = Segment.length(steps.first, segment.last)..Segment.length(steps.first, segment.first)
        end
 
        # Calculate point of segment in which we are now
        # steps.last stands for location of beginning stop
        trace['points'] << segment.intersection( *steps.first, distance )

        # TODO: what if null?

      rescue StopIteration
#        p footprint
        # p "rescued from StopIteration #{total_distance} - #{distance} meters from A"
        trace['points'] << steps.last
        break
      end
    end
    trace['points'].reverse!
    
    # We are at the beginning stop A
    trace
  end
end
