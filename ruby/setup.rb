#!/usr/bin/env ruby
# encoding: utf-8

require "couchrest"
require 'highline/import'

pass = ask("CouchDB password: "){|q| q.echo="*" }
db = CouchRest.database("http://Wasiutynski:#{pass}@db.wasiutynski.net/fake_blips")
podsadzacz = CouchRest.database("http://Wasiutynski:#{pass}@db.wasiutynski.net/podsadzacz_development")
file = File.new( Time.now.strftime("%Y-%m-%d") + ".txt", "w")

count = 0
blips = db.view("Blip/by_poly", :include_docs=>true)['rows'].map do |b|
  doc = b['doc']
  doc['poly'] = doc['beg'][0..15] + doc['end'][0..15]
  doc
end

blips.group_by{|b| b['poly']}.each_pair do |poly, blips|

  begin
    p poly
    polyline = podsadzacz.get(poly)
    file << poly + ":" + polyline['points'] + "\t" + blips.to_json + "\n"
    count += 1
  rescue
    p $!
  end    
end

print "Zapisano #{count} podróży do pliku #{file.path}.", "\n"

