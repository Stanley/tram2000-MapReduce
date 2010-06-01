file = File.new( Time.now.strftime("%Y-%m-%d") + ".txt", "w")

count = 0
Blip.by_poly.group_by{|b| b.poly}.each_pair do |poly, blips|
  begin
    polyline = Polyline.get(poly) || raise("Polyline \"" + poly + "\" was not found")
    file << polyline.points + "\t" + blips.to_msgpack + "\n"
    count += 1
  rescue
    p $!
  end    
end

p "Zapisano " + count.to_s + " podróży."

