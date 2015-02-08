use lib "/home/chimpsha/lib";
use Cards;
use Data::Dumper;
use utf8;
use encoding 'UTF-8';

#my %categories = Cards::category();
my %categories = ("Architects" => 1,
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
"Syndicate" => 15);

#my %set = Cards::edition();
my %set = ("Empire of Evil" => 18,
           "Combat in Kowloon" => 19,
           "Back for Seconds" => 20,
           "Reloaded" => 21,
           "Reinforcements" => 22,
           "Revelations" => 23,
          );
#my %rarity = Cards::rarity();
my %rarity = (
	      "Rare" => 1,
	      "R" => 1,
	      "Common" => 2,
	      "Uncommon" => 3,
              "Promo" => 6, 
              "Fixed" => 5,
              "F" => 5,
);
#my %types = Cards::types();
my %types = ("Site" => 1,
"Edge" => 2,
"State" => 3,
"Event" => 4,
"Char" => 5,
"Other" => 6,
"FSS" => 7);

# Useful bit for deleting aborted previous runs
# 1	Flashpoint
# 2	Limited / Standard
# 3 	Netherworld
# 4	Netherworld 2
# 5	Throne War
# 6 	Year of the Dragon
# 7 	Shaolin Showdown
# 8 	Dark Future
# 9	Boom Chaka Laka
# 11 	10,000 Bullets
# 12	Red Wedding
# 13	Seven Masters
# 14	Two-Fisted Tales
# 15 	Shurikens and Six-Guns
# 16	Promotional
# 17 	Critical Shift
# 18 	Empire of Evil
# 19    Combat in Kowloon
# 20    Back for Seconds

# 21    Reloaded
# 22    Reinforcements
# 23    Revelations


print "SELECT COUNT(*) FROM card;\n";
print "begin;\n";

use Text::xSV;
my $csv = new Text::xSV;
$csv->read_header();

sub infer_type {
    my $subtitle = shift;
    return "FSS" 
        if ($subtitle =~ /Feng Shui Site/);
    return "Site"
        if ($subtitle =~ /Site/);
    return "Edge"
        if ($subtitle =~ /Edge/);
    return "State"
        if ($subtitle =~ /State/);
    return "Event"
        if ($subtitle =~ /Event/);
    return "Char";  # Default

# Useful bit for deleting aborted previous runs
}

$edition = -1;
my %factions = ();
while (my @card = $csv->get_row()) {
    my $nomax = "N";

    my ($faction, $cardname, $subtitle, $fight, $power_gen, $body, 
	$req, $provide, $text,
	$flavor, $artist, $set, $rarity) = @card;
    ($req, $provide, $text) = map { local $_ = $_; s/\{/\[/g; s/\}/\] /g; $_ } ($req, $provide, $text);

    $req =~ /^((?:\[\w+\] )*)(\d+)$/;
    $req = $1;
    $cost = $2;
    
    if ($faction eq "Unaligned" || $faction eq "Neutral" ) {
        $faction = "Feng Shui Site"
	    if ($subtitle =~ /Feng Shui Site/);
        $faction = "Magic"
	    if ($req =~ /[Mag]/ or
	        $provide =~ /[Mag]/);
        $faction = "Chi"
	    if ($req =~ /[Chi]/ or
	        $provide =~ /[Chi]/);
        $faction = "High Tech"
	    if ($req =~ /[Tec]/ or
	        $provide =~ /[Tec]/);
    }
    if (exists $categories{$faction}) {
        $faction = $categories{$faction};
    } else {
        $factions{$faction} = 1;
    }

    $set = $set{$set};
    if ($edition == -1) {
      $edition = $set;
      print "DELETE from card where card_edition_id = $edition;\n";
    }
    $comments = "";

    $nomax = "Y" if ($text =~ /^No Max./);
    $designators = "| " . Cards::desig_split($cardname, $subtitle) . " |";
    $cost = 100 if ($cost eq "X");
    $body = 100 if ($body eq "X") || ($cardname eq "Evil Twin vPAP");
    $fight = 100 if ($fight eq "X") || ($cardname eq "Evil Twin vPAP");
    $power_gen = 100 if ($power_gen eq "X");
    $cost = zero_null($cost);
    $power_gen = zero_null($power_gen);

    $type = infer_type($subtitle);

    #$body = $fightbody;
    #$fight = $fightbody;
    $body = 0 if ($type eq 'Char');
    $fight = 0 if ($type eq 'Site' or $type eq 'FSS');

    $body |= 0;
    $fight |= 0;

    $text = "Unique. " . $text
	if ($restrict =~ /Unique/);

    $text = "No Max. " . $text
	if ($restrict =~ /No Max/);

    $text = replace_resources($text);

    $req = resources($req);
    $provide = resources($provide);
    $rarity = $rarity{$rarity};
    $type = $types{$type};

    ($cardname, $subtitle, $req, $provide, $text, $flavor, $comments, $artist, $designators, $nomax) = map { local $_ = $_; s/“/"/g;  s/”/"/g; s/’/'/g ; db_quote($_) } 
     ($cardname, $subtitle, $req, $provide, $text, 
      $flavor, $comments, $artist, $designators, $nomax);

print "
INSERT INTO card (title, subtitle, cost, requires, provides,
		  fighting, power, body, text, flavor, comments, 
		  artist, card_type_id, card_cat_id, card_rarity_id,
		  card_edition_id, no_max_flag, designators)
VALUES ($cardname, $subtitle, $cost, $req, $provide, 
	$fight, $power_gen, $body, $text, $flavor, $comments,
	$artist, $type, $faction, $rarity,
	$set, $nomax, $designators);
";
}


print "SELECT COUNT(*) FROM card;\n";
print "rollback;\n";
print "-- commit;\n";
print "SELECT COUNT(*) FROM card;\n";

if (%factions > 0) {
  use Data::Dumper;
  warn "Missing factions";
  warn join(", ", keys %factions);
}
