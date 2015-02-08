use lib "/home/chimpsha/lib";
use Cards;
use Data::Dumper;
use JSON;

#my %categories = Cards::category();
my %categories = ("Architects" => 1,
"Ascended" => 2,
"Chi" => 3,
"Dragons" => 4,
"Lotus" => 5, 
"FengShui" => 6,
"Monarchs" => 7,
"Hand" => 8,
"High Tech" => 9,
"Jammers" => 10,
"Magic" => 11,
"Unaligned" => 12,
"Feng Shui Site" => 12,
"Purists" => 13,
"Seven Masters" => 14,
"Syndicate" => 15);

#my %set = Cards::edition();
my %set = ("Empire of Evil" => 18);
#my %rarity = Cards::rarity();
my %rarity = ("Rare" => 1,
	      "Common" => 2,
	      "Uncommon" => 3,
"Promo" => 6, );
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
print "DELETE from card where card_edition_id = 18;\n";

print "begin;\n";

use Text::xSV;
my $csv = new Text::xSV;
$csv->read_header();

while (my @card = $csv->get_row()) {
    my $nomax = "N";

    my ($cardname, $type, $subtitle, $faction,
	$req, $cost, $provide, $power_gen, $fightbody, 
	$restrict, $abilities, $text,
	$flavor, $artist, $set, $rarity) = @card;
    if ($faction eq "Unaligned") {
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
    $faction = $categories{$faction};

    $set = $set{$set};
    $comments = "";

    $nomax = "Y" if ($text =~ /^No Max./);
    $designators = "| " . Cards::desig_split($cardname, $subtitle) . " |";
    warn "$cardname" if $cost eq "X";
    $cost = 100 if ($cost eq "X");
    $fightbody = 100 if ($fightbody eq "X");
    $power_gen = 100 if ($power_gen eq "X");
    $cost = zero_null($cost);
    $fightbody = zero_null($fightbody);
    $power_gen = zero_null($power_gen);

    $body = $fightbody;
    $fight = $fightbody;
    $body = 0 if ($type eq 'Char');
    $fight = 0 if ($type eq 'Site' or $type eq 'FSS');

    $text = "Unique. " . $text
	if ($restrict =~ /Unique/);

    $text = "No Max. " . $text
	if ($restrict =~ /No Max/);

    $text = replace_resources($text);

    $req = resources($req);
    $provide = resources($provide);
    $rarity = $rarity{$rarity};
    $type = $types{$type};

    map { $$_ = db_quote($$_) } 
     (\$cardname, \$subtitle, \$req, \$provide, \$text, 
      \$flavor, \$comments, \$artist, \$designators, \$nomax);

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


print "rollback;\n";
print "--commit;\n";
