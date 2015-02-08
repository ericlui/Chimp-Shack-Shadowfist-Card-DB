use lib "/home/chimpsha/lib";
use Cards;
use Data::Dumper;

my %categories = Cards::category();
$categories{'Syndicate'} = 'y';  # Hack around terrible standards in output file
my %set = Cards::edition();
my %rarity = Cards::rarity();
my %types = Cards::types();

print "DELETE from card where card_edition_id = 15;";

while (<STDIN>) {
    my ($cardname, $type, $subtitle, $faction,
	$req, $cost, $provide, $fight, $text,
	$flavor, $artist, $set, $rarity);
    my $nomax = "N";

    my @card = split /\t/,$_;
    map { s/^"(.*)"$/$1/; } @card;
    map { s/""/"/g; } @card;
    my ($cardname, $type, $subtitle, $faction,
	$req, $cost, $provide, $power_gen, $fightbody, $text,
	$flavor, $artist, $set, $rarity) = @card;
    $faction = $categories{$faction};
    $faction = 6 
	if ($subtitle eq "Feng Shui Site");
    $set = $set{$set};
    $comments = "";

    $nomax = "Y" if ($text =~ /^No Max./);
    $designators = Cards::desig_split($cardname, $subtitle);
    $cost = zero_null($cost);
    $fightbody = zero_null($fightbody);
    $power_gen = zero_null($power_gen);

    $body = $fightbody;
    $fight = $fightbody;
    $body = 0 if ($type eq 'char');
    $fight = 0 if ($type eq 'site' or $type eq 'fss');

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
		  card_edition_id, no_max_flag)
VALUES ($cardname, $subtitle, $cost, $req, $provide, 
	$fight, $power_gen, $body, $text, $flavor, $comments,
	$artist, $type, $faction, $rarity,
	$set, $nomax);
";
}


