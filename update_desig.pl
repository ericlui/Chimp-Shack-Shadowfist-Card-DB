use lib "/home/chimpsha/lib/";
use Cards;

my $dbh = Cards::createHandle;

my $sql = "select card_id, title, subtitle from card";
my $sth = $dbh->prepare($sql);

$sth->execute();
$sth->bind_columns(\$id, \$title, \$subtitle);

while ($sth->fetch()) {
    $designators = Cards::desig_split($title, $subtitle);
    # Quotify the designators, and add the secret sauce-- padding
    # the designator field with a leading/trailing space allows
    # for perfect word-boundary matching
    $designators = db_quote("| $designators |");
    print "UPDATE card set designators = $designators 
	   WHERE card_id = $id;
	   ";
}


