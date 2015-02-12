CATEGORIES = { "Architects" => 1,
              "Ascended" => 2,
              "Chi" => 3,
              "Dragons" => 4,
              "Lotus" => 5, 
              "Eaters of the Lotus" => 5, 
              "FengShui" => 6,
              "Monarchs" => 7,
              "Hand" => 8,
              "The Guiding Hand" => 8,
              "High Tech" => 9,
              "Jammers" => 10,
              "Magic" => 11,
              "Unaligned" => 12,
              "Neutral" => 12,
              "Feng Shui Site" => 12,
              "Purists" => 13,
              "Seven Masters" => 14,
              "Syndicate" => 15 
             }

SETS = { "Empire of Evil" => 18,
        "Combat in Kowloon" => 19,
        "Back for Seconds" => 20,
        "Reloaded" => 21,
        "Reinforcements" => 22,
        "Revelations" => 23,
        "Queen's Gambit" => 24,
        "Knight's Passage" => 25, 
        "Endgame" => 26
      }

RARITIES = {
        "Rare" => 1,
        "R" => 1,
        "Common" => 2,
        "Uncommon" => 3,
        "Fixed" => 5,
        "F" => 5,
        "Promo" => 6
         }

TYPES = { "Site" => 1,
          "Edge" => 2,
          "State" => 3,
          "Event" => 4,
          "Char" => 5,
          "Other" => 6,
          "FSS" => 7
        }


CAT_SYMBOL = {
    '{mag}'=>'M' , 
    '{arch}'=>'f', 
    '{arc}'=>'f', 
    '{asc}'=>'a' , 
    '{chi}'=>'C' , 
    '{dra}'=>'d' , 
    '{lot}'=>'e' , 
    '{mon}'=>'m' , 
    '{hand}'=>'g' , 
    '{han}'=>'g' , 
    '{tech}'=>'H' , 
    '{tec}'=>'H' , 
    '{jam}'=>'j' , 
    '{pur}'=>'p' , 
    '{sev}'=>'s',
    '{syn}'=>'y',
             }


# card headers
FACTION = "Faction"
TITLE = "Title"
SUBTITLE = "Subtitle"
FIGHTING = "Fighting"
POWER = "Power"
BODY = "Body"
REQUIRES = "Requires"
PROVIDES = "Provides"
TEXT = "Text"
TAG = "Tag"
ARTIST = "Artist"
SET = "Set"
RARITY = "Rarity"

INTEGERS = [ FIGHTING, BODY, POWER]

def infer_type (subtitle) 
  return "FSS" if subtitle =~ /Feng Shui Site/
  return "Site" if subtitle =~ /Site/
  return "Edge" if subtitle =~ /Edge/
  return "State" if subtitle =~ /State/
  return "Event" if subtitle =~ /Event/
  "Char"
end

def find_faction(card)
  faction = card[FACTION]
  subtitle = card[SUBTITLE]
  card[REQUIRES] ||= ""
  card[PROVIDES] ||= ""
  resources = card[REQUIRES] + card[PROVIDES]
  if (faction == "Unaligned" || faction == "Neutral")
    faction = "Feng Shui Site" if (subtitle =~ /Feng Shui Site/);
    faction = "Magic" if (resources =~ /[Mag]/)
    faction = "Chi" if (resources =~ /[Chi]/)
    faction = "High Tech" if (resources =~ /[Tec]/)
  end
  faction = CATEGORIES[faction] || 1
end

def build_designators(card) 
  designators = card[TITLE].split(/[ \/\-]/) + card[SUBTITLE].split(/[ \/\-]/)
  designators.map{ |word| cleanup(word) }.flatten
    .select {|w| not /^(a|an|the|and|or|but|nor|at|for|in|into|of|on|to|with|within|without|Event|State|Feng|Shui|Site|Edge)$/.match(w) }
    .uniq.join(" ")
end

def cleanup(word) 
  word.gsub(/["'\!\?,(...)]/, "")
  word = word.downcase == "vpap" ? "" : word
  words = word.split(/(?<=[a-z])(?=[A-Z])/)
  words = words.map { special_designators(word) }.flatten
  words = words.map { depluralize(word) }.flatten
end

def depluralize(w) 
  if (w == "darkness") 
    [w, "darknes", "darkne", "darkn" ]
  elsif (/ies$/.match(w))
    [w, $` + "y", $`]
  elsif (/es$/.match(w))
    [w, $` + "e", $`]
  elsif (/s$/.match(w)) 
    [w, $`]   
  elsif (/men$/.match(w))
    [w, $` + "man"]
  else 
    [w]
  end
end

def special_designators(w) 
  if (/(sword|gun|buro)(?:s)?(.*)/.match(w)) 
    [Regexp.last_match(1), Regexp.last_match(2)]
  elsif (/(super|arcano)(.*)/.match(w))
    [Regexp.last_match(1), Regexp.last_match(2)]
  else
    [ w ]      
  end
end

def quote(s) 
  "'" + s.gsub(/\\/, '\&\&').gsub(/'/, "''") + "'" # ' (for ruby-mode)
end

def replace_resources(text) 
  text.gsub(/\{(\w{3,4})\}/) { |m| "[#{CAT_SYMBOL[m]}]" }
end

def resources(text) 
  text.gsub(/\{\w{3,4}\}/) { |m| CAT_SYMBOL[m]}
end

def rarities(rarity) 
  RARITIES[rarity]
end

def sets(name) 
  SETS[name]
end

def types(type)
  TYPES[type]
end

