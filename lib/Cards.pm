package Cards;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(zero_null db_quote resources type_map replace_resources);
@EXPORT = qw(zero_null db_quote resources type_map replace_resources);
use DBI;
use Data::Dumper;
use strict;


my $targetdb = "chimpsha_fistdb";       # defined later in &setdb
my $loginfile= ".dbilogin";
my $handle;

# Create a database handle (publicly accessible)

sub setPlayTest {
    $targetdb = "chimpsha_fistpt";
}

sub createHandle {
    my $type = shift;
    if ($handle != undef) {
	return $handle;
    }
    if ($type eq "updater") {
	return DBI->connect("DBI:mysql:$targetdb",'chimpsha_fistwri','*****');
    }
      
    if(open F, $loginfile) { 
      chomp(my $f=<F>);
      close F;
      my ($dbuser, $dbpasswd,$db)=split /\|/,$f;
      $handle = DBI->connect("DBI:mysql:$db",$dbuser,$dbpasswd);
    } else { 
      $handle = DBI->connect("DBI:mysql:$targetdb",'chimpsha_fistrea','g1mm3');
    }
    return $handle;
}

# Specify the database to reference
sub setdb {
    my $db = shift;
    $targetdb = "shadowfistdb";
    $targetdb = "shadowfist_pt" if ($db eq "playtest");

    return 0;
}
######################################################################
# option_set ($kind)
# all the interesting stuff here is in the side effects - printing
# HTML option tags for the different table types (type, cat, edition,
# and rarity)
######################################################################
sub option_set {
    my ($kind) = @_;

    my ($dbh, $inputs, $query);

    $dbh = &createHandle();

    $query = "select $kind from card_$kind ";
    if (($kind eq 'edition') || 
	($kind eq 'rarity')) 
    {
	$query .= "ORDER BY seq, card_$kind" . "_id";
    } 
    else
    {
	$query .= "ORDER BY card_$kind" . "_id";
    }
     
    $inputs = $dbh->selectcol_arrayref($query);

    print "<option selected>Any\n";

    foreach (@$inputs) {
	print "<option>$_\n";
    }
    
    return 1;
}

my %cat_shorthand = (
    '[Mag]' => 'Magic',
    '[Arch]' => 'Architects of the Flesh',
    '[Arc]' => 'Architects of the Flesh',
    '[Asc]' => 'Ascended',
    '[Chi]' => 'Chi',
    '[Dra]' => 'Dragons',
    '[Lot]' => 'Eaters of the Lotus',
    '[FSS]' => 'Feng Shui Site',
    '[Mon]' => 'Four Monarchs',
    '[Hand]'  => 'Guiding Hand',
    '[Tech]' => 'High Tech',
    '[Jam]' => 'Jammers',
    '[Un]'  => 'Unaligned',
    '[Pur]' => 'Purists',
    '[Sev]' => 'Seven Masters',
    '[Syn]' => 'Shadow Syndicate',
);

my %cat_full_symbol = (
    'Magic' => '[M]',
    'Architects of the Flesh' => '[f]',
    'Ascended' => '[a]',
    'Chi' => '[C]',
    'Dragons' => '[d]',
    'Eaters of the Lotus' => '[e]',
    'Feng Shui Site' => "FUNNY ERROR",
    'Four Monarchs' => '[m]',
    'Guiding Hand' => '[g]',
    'High Tech' => '[H]',
    'Jammers' => '[j]',
    'Unaligned' => "FUNNY ERROR",
    'Purists' => '[p]',
    'Seven Masters' => '[s]',
    'Shadow Syndicate' => '[y]',
);

my %symbol_cat = (
    'M'=>'[Mag]' , 
    'f'=>'[Arch]', 
    'a'=>'[Asc]' , 
    'C'=>'[Chi]' , 
    'd'=>'[Dra]' , 
    'e'=>'[Lot]' , 
    'm'=>'[Mon]' , 
    'g'=>'[Hand]', 
    'H'=>'[Tech]', 
    'j'=>'[Jam]' , 
    'p'=>'[Pur]' , 
    's'=>'[Sev]',
    'y'=>'[Syn]',
);

my %cat_symbol = (
    '[Mag]'=>'M' , 
    '[Arch]'=>'f', 
    '[Arc]'=>'f', 
    '[Asc]'=>'a' , 
    '[Chi]'=>'C' , 
    '[Dra]'=>'d' , 
    '[Lot]'=>'e' , 
    '[Mon]'=>'m' , 
    '[Hand]'=>'g' , 
    '[Han]'=>'g' , 
    '[Tech]'=>'H' , 
    '[Tec]'=>'H' , 
    '[Jam]'=>'j' , 
    '[Pur]'=>'p' , 
    '[Sev]'=>'s',
    '[Syn]'=>'y',
)
;

# map over alternate keys
foreach (keys(%cat_symbol)) {
  my $key = $_;
  $cat_symbol{lc($_)} = $cat_symbol{$key};
  tr/][//d;
  $cat_symbol{$_} = $cat_symbol{$key};
}

my %type_map = (
    'site' => 1,
    'fss' => 1,
    'edge' => 2,
    'state' => 3,
    'event' => 4,
    'char' => 5,
);

###########################################################
# Designator handling
# Accepts title, subtitle string
# Returns a designator string
###########################################################

sub desig_split {
    my ($title, $subtitle) = @_;
    my ($designators);
    my @designators = split (/[ \/\-]/, $title . " " . $subtitle);

    #Strip out punctuation
    map s/["'\!\?,(...)]//g, @designators;

    # Handle capitals - must do this before lowercasing
    @designators = map { &splitcaps($_); } @designators;

    # Remove disallowed words
    @designators = grep !/^(a|an|the|and|or|but|nor|at|for|in|into|of|on|to|with|within|without|Event|State|Feng|Shui|Site|Edge)$/, @designators;

    # Lower-case
    @designators = map { lc; } @designators;

    # Handle Special words (Sword, Gun, Arcano, Super, Buro)
    @designators = map { &desigspecials($_); } @designators;

    # Handle plurals
    @designators = map { &depluralize($_); } @designators;
    # Remove duplicates
    my %seen = ();
    @designators = grep { ! $seen{$_}++ } @designators;

    $designators = join " ", @designators;
    
    return $designators;
}

# depluralize returns an array of a word and its potential singular variants
sub depluralize {
    my $word = shift;
    if ($word eq "darkness") {
	return ($word, "darknes", "darkne","darkn");
    }
    if ($word =~ /(.*)ies$/) {
	return ($1 . "y", $1, $word);
    }
    if ($word =~ /(.*)es$/) {
	return ($1, $1 . "e", $word);
    }
    if ($word =~ /(.*)s$/) {
	return ($1, $word);
    }
    if ($word =~ /(.*)men$/) {
	return ($1 . "man", $1 . "men");
    }

    return ($word);
}

# splitcaps handles MegaTank, discards vPap
sub splitcaps {
    my $word = shift;

    if ($word =~ /vpap/i) {
	return ();
    }

    if ($word =~ /(.*[a-z])([A-Z].*)/) {
	return ($1, $2);
    }

    return ($word);
}

# desigspecials handles special keywords
sub desigspecials {
    my $word = shift;
    if ($word =~ /(sword(s)?)(.*)/) {
	return ($1, $3);
    }
    if ($word =~ /(gun(s)?)(.*)/) {
	return ($1, $3);
    }

    if ($word =~ /(buro)(.*)/) {
        return ($1, $2);
    }
    # Don't do plural of Super-- too many common matches
    if ($word =~ /(super)(.*)/) {
	return ($1, $2);
    }
    # don't do plural of Arcano, too many common matches
    if ($word =~ /(arcano?)(.*)/) {
	return ($1, $2);
    }

    return ($word);
}

sub remove_s {
    my $word = shift;
    if ($word =~ /(.+)es$/) {
	return ($1);
    }
    if ($word =~ /(.+)s$/) {
	return ($1);
    }
    return ($word);
}

sub zero_null {
    my $num = shift;
    return 0 if ($num eq "");
    return $num;
}

sub db_quote {
    my $text = shift;
    my $dbh = createHandle();
    $text = $dbh->quote($text);
    $dbh->disconnect;
    return $text;
}
###########################################################
# Subroutine wrappers to return useful hashes
###########################################################
sub shorthand {
    return %cat_shorthand;
}

sub full_shorthand {
    my %full_shorthand;
    foreach (keys %cat_shorthand) {
	$full_shorthand{$cat_shorthand{$_}} = $_;
    }
    return %full_shorthand;
}

sub symbol {
    return %cat_symbol;
}

sub full_symbol {
    return %cat_full_symbol;
}

sub cats {
  return wantarray() ? %symbol_cat : \%symbol_cat;
}

sub types {
    return %type_map;
}

# Return Julian's short_names for the various card types
# so i can normalize them into the table properly
sub short_types {
    my ($dbh, $sth, $query, $type, $short_name);
    my %types;

    $dbh = &createHandle();

    $query = "select card_type_id, short_name from card_type";
    $sth = $dbh->prepare($query);
    $sth->execute();
    
    $sth->bind_columns(\$type, \$short_name);

    while ($sth->fetch()) {
	$types{$short_name} = $type;
    }
    
    $dbh->disconnect();

    return %types;

}

# eg., "Syndicate" => "y"
sub categories_short {
    my ($dbh, $sth, $query, $cat, $code);
    my %categories;

    $dbh = &createHandle();

    $query = "SELECT cat_short, code FROM card_cat";
    $sth = $dbh->prepare($query);
    $sth->execute();
    $sth->bind_columns(\$cat, \$code);

    while ($sth->fetch()) {
	$categories{$cat} = $code;
    }
    $dbh->disconnect();
   
    return %categories;
}

# eg, "Architects of the Flesh" => "f"
sub categories {
    return query_hash("SELECT cat, code FROM card_cat");
}

sub rarity {
#    my ($dbh, $sth, $query, $key, $value);
#    my %rarities;

#    $dbh = &createHandle();

#    $query = "SELECT rarity, card_rarity_id FROM card_rarity";
#    $sth = $dbh->prepare($query);
#    $sth->execute();
#    $sth->bind_columns(\$key, \$value);

#    while ($sth->fetch()) {
#	$rarities{$key} = $value;
#    }
    
#    $dbh->disconnect();

#    return %rarities;
    return query_hash("SELECT rarity, card_rarity_id FROM card_rarity");
}

# return edition
sub edition {
    return query_hash("SELECT edition, card_edition_id FROM card_edition");
}

sub category {
    return query_hash("SELECT cat, card_cat_id FROM card_cat");
}

# Given a query that looks up two columns
# return a hash which maps the first value as key, the second as value
sub query_hash {
    my $query = shift;
    my ($dbh, $sth, $query, $key, $value);
    my %lookup;

    $dbh = &createHandle();

    $sth = $dbh->prepare($query);
    $sth->execute();
    $sth->bind_columns(\$key, \$value);

    while ($sth->fetch()) {
	$lookup{$key} = $value;
    }
    
    $dbh->disconnect();

    return %lookup;
}

# Given a string of resources of the format [Dra] [Dra]
# return the database format: dd
sub resources {
    my $in = shift;
    my @resources = split / /, $in;
    @resources = map { $cat_symbol{$_}} @resources;
    return join "",@resources;
}    

# Given a string containing resources,
# return the string with shortened resources
sub replace_resources {
    my $text = shift;

    $text =~ s/(\[(.)(\w+?)\])/\[\u$2$3\]/g;
    $text =~ s/(\[\w+?\])/\[$cat_symbol{$1}\]/g;
    return $text;
}
