file = File.new( Time.now.strftime("%Y-%m-%d") + ".txt", "w")

count = 0
Blip.by_poly.group_by{|b| b.poly}.each_pair do |poly, blips|
  begin
    polyline = Polyline.get(poly) || raise("Polyline \"" + poly + "\" was not found")
    file << poly + ":" + polyline.points + "\t" + blips.to_json + "\n"
    count += 1
  rescue
    p $!
  end    
end

p "Zapisano " + count.to_s + " podróży."

