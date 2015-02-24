# -*- coding: utf-8 -*- #specify UTF-8 (unicode) characters

require 'csv'
require 'set'
require_relative 'shadowfist_lib'


# Useful bit for deleting aborted previous runs
# 1 Flashpoint
# 2 Limited / Standard
# 3 Netherworld
# 4 Netherworld 2
# 5 Throne War
# 6 Year of the Dragon
# 7 Shaolin Showdown
# 8 Dark Future
# 9 Boom Chaka Laka
# 11  10,000 Bullets
# 12  Red Wedding
# 13  Seven Masters
# 14  Two-Fisted Tales
# 15  Shurikens and Six-Guns
# 16  Promotional
# 17  Critical Shift
# 18  Empire of Evil
# 19  Combat in Kowloon
# 20  Back for Seconds
# 21  Reloaded
# 22  Reinforcements
# 23  Revelations
# 24  Queen's Gambit
# 25  Knight's Passage
# 26  Endgame

puts "SELECT COUNT(*) FROM card;";
puts "begin;"
puts "DELETE from card where card_edition_id = $edition;"

factions = Set.new

ARGF.file do |file|

end


CSV.parse(ARGF.file, {:headers => true}).each do |card|
  nomax = (card[TEXT] =~ /^No Max./) ? "Y" : "N"
  comments = "''"

  req = /^(\D*)(\d+)$/.match(card[REQUIRES])
  if req 
    cost = req[2]
    card[REQUIRES] = req[1]
  end

  card[FACTION] = find_faction(card);
  edition = sets(card[SET])

  cost = 100 if (cost == "X")
  card[BODY] = 100 if (card[BODY] == "X") || (card[TITLE] == "Evil Twin vPAP")
  card[FIGHTING] = 100 if (card[FIGHTING] == "X") || (card[TITLE] == "Evil Twin vPAP")
  card[POWER] = 100 if card[POWER] == "X"

  type = infer_type(card[SUBTITLE]);

  card[TAG] ||= ""
  card[TEXT] = replace_resources(card[TEXT])
  card[REQUIRES] = resources(card[REQUIRES])
  card[PROVIDES] = resources(card[PROVIDES])

  card[RARITY] = rarities(card[RARITY])
  type = types(type)

  cost ||= 0

  INTEGERS.each do |key| 
    card[key] ||= 0
    card[key] = card[key].to_i
  end

  designators = "| " + build_designators(card) + " |"

  string_fields = []
  card.each do |key, value|
    if value.is_a? String
      card[key] = quote(value)
    end
  end

  nomax = quote(nomax)
  designators = quote(designators)

  puts "INSERT INTO card (title, subtitle, cost, requires, provides,
    fighting, power, body, text, flavor, comments, 
    artist, card_type_id, card_cat_id, card_rarity_id,
    card_edition_id, no_max_flag, designators)
VALUES (#{[card[TITLE], card[SUBTITLE], cost, card[REQUIRES], card[PROVIDES],
card[FIGHTING], card[POWER], card[BODY], card[TEXT], card[TAG], comments,
card[ARTIST], type, card[FACTION], card[RARITY],
edition, nomax, designators].join(', ')});\n\n"
end

puts "SELECT COUNT(*) FROM card;"
puts "rollback;"
puts "-- commit;"
puts "SELECT COUNT(*) FROM card;"

if (factions.size > 0) 
  warn "Missing factions"
  warn join(", ", factions.to_array);
end
