class Polyline

  # Decode polyline fron string
  # Returns: Array of coordinates ([lat,lng])
  def self.decode(polyline)

    encoded = polyline.each_byte.to_a
    len = encoded.length
    array = Array.new
    index = 0
    lat = 0
    lng = 0    

    while (index < len)
      shift = 0
      result = 0
      
      loop do
        a = encoded[index]
        b = a - 63
        result |= (b & 0x1f) << shift
        shift += 5
        index += 1
        break unless (b >= 0x20)
      end

      dlat = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1))
      lat += dlat

      shift = 0
      result = 0
      loop do
        a = encoded[index]
        b = a - 63
        result |= (b & 0x1f) << shift
        shift += 5
        index += 1
        break unless (b >= 0x20)
      end

      dlng = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1))
      lng += dlng
      array.push([lat * 1e-5, lng * 1e-5])
    end
    
    return array
  end  

  # Utility for creating Google Maps Encoded GPolylines
  # License: You may distribute this code under the same terms as Ruby itself
  # Author: Joel Rosenberg
  
  attr_accessor :reduce, :escape # zoomFactor and numLevels need side effects
  attr_reader :zoomFactor, :numLevels
  
  # The minimum distance from the line that a point must exceed to avoid
  # elimination under the DP Algorithm.
  @@dp_threshold = 0.00001
  
  def initialize(options = {})
    # There are no required parameters

    # Nice defaults
    @numLevels  = options.has_key?(:numLevels)  ? options[:numLevels]  : 18
    @zoomFactor = options.has_key?(:zoomFactor) ? options[:zoomFactor] : 2
    
    # Calculate the distance thresholds for each zoom level
    calculate_zoom_breaks()
    
    # By default we'll simplify the polyline unless told otherwise
    @reduce = ! options.has_key?(:reduce) ? true : options[:reduce]
    
    # Escape by default; most people are using this in a web context
    @escape = ! options.has_key?(:escape) ? true : options[:escape]
    
  end
  
  def numLevels=( new_num_levels )
    @numLevels = new_num_levels
    # We need to recalculate our zoom breaks
    calculate_zoom_breaks()
  end
  
  def zoomFactor=( new_zoom_factor )
    @zoomFactor = new_zoom_factor
    # We need to recalculate our zoom breaks
    calculate_zoom_breaks()
  end
  
  def encode( points )
  
    # This is an implementation of the Douglas-Peucker algorithm for simplifying
    # a line. You can thing of it as an elimination of points that do not
    # deviate enough from a vector. That threshold for point elimination is in
    # @@dp_threshold. See: http://everything2.com/index.pl?node_id=859282
    #
    # for an explanation of the algorithm
    
    max_dist = 0  # Greatest distance we measured during the run
    stack = []
    distances = Array.new(points.size)
  
    if(points.length > 2)
      stack << [0, points.size-1]
      
      while(stack.length > 0) 
        current_line = stack.pop()
        p1_idx = current_line[0]
        pn_idx = current_line[1]
        pb_dist = 0
        pb_idx = nil
        
        x1 = points[p1_idx][0]
        y1 = points[p1_idx][1]
        x2 = points[pn_idx][0]
        y2 = points[pn_idx][1]
        
        # Caching the line's magnitude for performance
        magnitude = Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
        magnitude_squared = magnitude ** 2
        
        # Find the farthest point and its distance from the line between our pair
        for i in (p1_idx+1)..(pn_idx-1)
        
          # Refactoring distance computation inline for performance
          #current_distance = compute_distance(points[i], points[p1_idx], points[pn_idx])
          
          # 
          # This uses Euclidian geometry. It shouldn't be that big of a deal since
          # we're using it as a rough comparison for line elimination and zoom
          # calculation.
          #
          # TODO: Implement Haversine functions which would probably bring this to
          #       a snail's pace (ehhhh)
          #
    
          px = points[i][0]
          py = points[i][1]
         
          current_distance = nil
          
          if( magnitude == 0 )
            # The line is really just a point
            current_distance = Math.sqrt((x2-px)**2 + (y2-py)**2)
          else
         
            u = (((px - x1) * (x2 - x1)) + ((py - y1) * (y2 - y1))) / magnitude_squared
            
            if( u <= 0 || u > 1 )
                # The point is closest to an endpoint. Find out which one
                ix = Math.sqrt((x1 - px)**2 + (y1 - py)**2)
                iy = Math.sqrt((x2 - px)**2 + (y2 - py)**2)
                if( ix > iy )
                  current_distance = iy
                else
                  current_distance = ix
                end
            else
                # The perpendicular point intersects the line
                ix = x1 + u * (x2 - x1)
                iy = y1 + u * (y2 - y1)
                current_distance = Math.sqrt((ix - px)**2 + (iy - py)**2)
            end
          end
          
          # See if this distance is the greatest for this segment so far
          if(current_distance > pb_dist)
            pb_dist = current_distance
            pb_idx = i
          end
        end
        
        # See if this is the greatest distance for all points
        if(pb_dist > max_dist)
          max_dist = pb_dist
        end
        
        if(pb_dist > @@dp_threshold)
          # Our point, Pb, that had the greatest distance from the line, is also
          # greater than our threshold. Process again using Pb as a new 
          # start/end point. Record this distance - we'll use it later when
          # creating zoom values
          distances[pb_idx] = pb_dist
          stack << [p1_idx, pb_idx]
          stack << [pb_idx, pn_idx]
        end
        
      end
    end
    
    # Force line endpoints to be included (sloppy, but faster than checking for
    # endpoints in encode_points())
    distances[0] = max_dist
    distances[distances.length-1] = max_dist
  
    # Create Base64 encoded strings for our points and zoom levels
    points_enc = encode_points( points, distances)
    levels_enc = encode_levels( points, distances, max_dist)
    
    # Make points_enc an escaped string if desired.
    # We should escape the levels too, in case google pulls a switcheroo
    @escape && points_enc && points_enc.gsub!( /\\/, '\\\\\\\\' )
   
    
    # Returning a hash. Yes, I am a Perl programmer
    return {
      :points     => points_enc,
      :levels     => levels_enc,
      :zoomFactor => @zoomFactor,
      :numLevels  => @numLevels,
    }
    
  end
  
  private
  
  def calculate_zoom_breaks()
    # Calculate the distance thresholds for each zoom level
    @zoom_level_breaks = Array.new(@numLevels);
    
    for i in 0..(@numLevels-1)
      @zoom_level_breaks[i] = @@dp_threshold * (@zoomFactor ** ( @numLevels-i-1));
    end
    
    return
  end
  
  def encode_points( points, distances )
    encoded = ""
    
    plat = 0
    plon = 0

    #points.each do |point| # Gah, need the distances.
    for i in 0..(points.size() - 1)
      if(! @reduce || distances[i] != nil )
        point = points[i]
        late5 = (point[0] * 1e5).floor();
        lone5 = (point[1] * 1e5).floor();

        dlat = late5 - plat
        dlon = lone5 - plon

        plat = late5;
        plon = lone5;

        # I used to need this for some reason
        #encoded << encodeSignedNumber(Fixnum.induced_from(dlat)).to_s
        #encoded << encodeSignedNumber(Fixnum.induced_from(dlon)).to_s
        encoded << encodeSignedNumber(dlat).to_s
        encoded << encodeSignedNumber(dlon).to_s
      end
    end

    return encoded

  end
  
  def encode_levels( points, distances, max_dist )
    
    encoded = "";
    
    # Force startpoint
    encoded << encodeNumber(@numLevels - 1)
    
    if( points.size() > 2 )
      for i in 1..(points.size() - 2)
        distance = distances[i]
        if( ! @reduce || distance != nil)
          computed_level = 0
        
          while (distance and (distance < @zoom_level_breaks[computed_level])) do
            computed_level += 1
          end
          
          encoded << encodeNumber( @numLevels - computed_level - 1 )
        end
      end
    end
    
    # Force endpoint
    encoded << encodeNumber(@numLevels - 1)
    
    return encoded;
    
  end
 
  def compute_distance( point, lineStart, lineEnd )
  
    #
    # Note: This has been refactored to encode() inline for performance and 
    #       computation caching
    #
    
    px = point[0]
    py = point[1]
    x1 = lineStart[0]
    y1 = lineStart[1]
    x2 = lineEnd[0]
    y2 = lineEnd[1]
   
    distance = nil
   
    magnitude = Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
    
    if( magnitude == 0 )
      return Math.sqrt((x2-px)**2 + (y2-py)**2)
    end
   
    u = (((px - x1) * (x2 - x1)) + ((py - y1) * (y2 - y1))) / (magnitude**2)
    
    if( u <= 0 || u > 1 )
        # The point is closest to an endpoint. Find out which
        ix = Math.sqrt((x1 - px)**2 + (y1 - py)**2)
        iy = Math.sqrt((x2 - px)**2 + (y2 - py)**2)
        if( ix > iy )
          distance = iy
        else
          distance = ix
        end
    else
        # The perpendicular point intersects the line
        ix = x1 + u * (x2 - x1)
        iy = y1 + u * (y2 - y1)
        distance = Math.sqrt((ix - px)**2 + (iy - py)**2)
    end
    
    return distance
  end
  
  def encodeSignedNumber(num)
    # Based on the official google example
    
    sgn_num = num << 1

    if( num < 0 )
        sgn_num = ~(sgn_num)
    end

    return encodeNumber(sgn_num)
  end

  def encodeNumber(num)
    # Based on the official google example
    
    encoded = "";

    while (num >= 0x20) do
        encoded << ((0x20 | (num & 0x1f)) + 63).chr;
        num = num >> 5;
    end

    encoded << (num + 63).chr;
    return encoded;
  end
end
