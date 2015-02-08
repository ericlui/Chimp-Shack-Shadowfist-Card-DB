use lib "/home/chimpsha/lib/";
use Cards;

#Generic record updater.  Searches on some criteria, 
# iterates through records, and runs an update
# statement for each one.
my $dbh = Cards::createHandle;

my $sql = "select card_id, flavor from card where flavor like '%quot%'";
my $sth = $dbh->prepare($sql);

$sth->execute();
$sth->bind_columns(\$id, \$flavor);

while ($sth->fetch()) {
    $flavor =~ s/&quot;/"/g;
    # Quotify the designators, and add the secret sauce-- padding
    # the designator field with a leading/trailing space allows
    # for perfect word-boundary matching
    $flavor = db_quote("$flavor");
    print "UPDATE card set flavor = $flavor 
	   WHERE card_id = $id;
	   ";
}


