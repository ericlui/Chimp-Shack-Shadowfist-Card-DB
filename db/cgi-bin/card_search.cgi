#!/usr/bin/perl

use strict;
use CGI;
use DBI;
use lib ("/home/chimpsha/lib");
use Cards;

# initialize some useful hashes
my %cat_shorthand = &Cards::shorthand();
my %full_shorthand = &Cards::full_shorthand();
my %cat_symbol = &Cards::symbol();
my $symbol_cat = &Cards::cats();

# Some security stuff for CGI.pm
$CGI::POST_MAX=10240;
$CGI::DISABLE_UPLOADS = 1;

# Get form data
my $cgi = new CGI;

# Create db handles

my ($dbh, $sth);
my $loginfile='.dbilogin';

my (@record);
if(open F, $loginfile) { 
  chomp(my $f=<F>);
  close F;
  my ($dbuser, $dbpasswd,$db)=split /\|/,$f;
  $dbh = DBI->connect($db,$dbuser,$dbpasswd)
    or die "<h1>Can't open database.</h1></body>/html>";
}

$dbh = Cards::createHandle();

# Set the search type
my $search;
if ($cgi->param('case_sense') eq 'on') { $search = \&search_with_case }
else { $search = \&search_no_case }

# Create a search query
my @found;

my @criteria;

# do a few transforms on data to make X := 100
$cgi->param('fighting',100) 
    if ($cgi->param('fighting') =~ /x/i);
$cgi->param('cost', 100)
    if ($cgi->param('cost') =~ /x/i);

# Generate WHERE clauses
push @criteria, "type = '" . $cgi->param('type') . "'"
    if ($cgi->param('type') ne 'Any');
push @criteria, "cost = " . $cgi->param('cost')
    if ($cgi->param('cost') ne '');
# handle Requires and Provides differently, since they're stored in-line
push @criteria, 'requires like "%' . $cgi->param('requires') . '%"'
    if ($cgi->param('requires') ne 'Any');
push @criteria, 'requires = ""'
    if ($cgi->param('requires') eq "");
push @criteria, 'provides like "%' . $cgi->param('provides') . '%"'
    if ($cgi->param('provides') ne 'Any');
push @criteria, 'provides = ""'
    if ($cgi->param('provides') eq "");
push @criteria, "fighting = " . $cgi->param('fighting')
    if ($cgi->param('fighting') ne '');
push @criteria, "power = " . $cgi->param('power')
    if ($cgi->param('power') ne '');
push @criteria, "body = " . $cgi->param('body')
    if ($cgi->param('body') ne '');
if ($cgi->param('edition') ne 'Any') {
  if ($cgi->param('edition') =~ m/FORMAT$/) {
    push @criteria, "card.card_edition_id > 18";
  } else {
    push @criteria, "edition = " . $dbh->quote($cgi->param('edition'));
  } 
}
push @criteria, "rarity = '" . $cgi->param('rarity') . "'"
    if ($cgi->param('rarity') ne 'Any');

#push @criteria, "cat = '" . $cgi->param('category') . "'"
#    if ($cgi->param('category') ne 'Any');
push @criteria, faction_where($cgi->param('category'))
    if ($cgi->param('category') ne 'Any');

# Multiple entries possible - AND, OR, NOT?
push @criteria, &$search('title',
			 $cgi->param('title_bool'),
			 $cgi->param('title'), 
			 $dbh)
    if ($cgi->param('title') ne '');
push @criteria, &$search('subtitle',
			 $cgi->param('subtitle_bool'),
			 $cgi->param('subtitle'), 
			 $dbh)
    if ($cgi->param('subtitle') ne '');
push @criteria, &$search('designators',
			 $cgi->param('designator_bool'),
			 $cgi->param('designator'),
			 $dbh) 
    if ($cgi->param('designator') ne '');
push @criteria, &$search('text',
			 $cgi->param('text_bool'),
			 $cgi->param('text'),
			 $dbh)
    if ($cgi->param('text') ne '');
push @criteria, &$search('flavor',
			 $cgi->param('flavor_bool'),
			 $cgi->param('flavor'),
			 $dbh)
    if ($cgi->param('flavor') ne '');
push @criteria, &$search('comments',
			 $cgi->param('comments_bool'),
			 $cgi->param('comments'),
			 $dbh)
    if ($cgi->param('comments') ne '');
push @criteria, &$search('artist',
			 $cgi->param('artist_bool'),
			 $cgi->param('artist'),
			 $dbh)
    if ($cgi->param('artist') ne '');

my $query = &generate_query($cgi,@criteria);

#use Data::Dumper;
open FILE, ">>/home/chimpsha/tmp/log";
#print FILE &Dumper(\@elements) . " is my search string\n";
print FILE $query . "\n";
close FILE;


$sth = $dbh->prepare($query);

$sth->execute() 
    or die $sth->errstr . "$query";

while (@record = $sth->fetchrow) {
    my $card = &convert_record(@record);
    
    push @found, $card;
}

# Output the results from our search, converting the resource
# abbreviations into symbols with URL <img src="[symbol].gif">
# if the graphics box is checked, and the rarity abbreviations
# into something meaningful.

# Throw the header out there first
print <<HEADER;
Content-type: text/html

<html>
<head>
<title>Search results</title>
<link rev="made" href="mailto:searchmonkey\@chimpshack.org">
<meta name="author" content="searchmonkey\@chimpshack.org">
<meta name="generator" content="card_search.cgi">
</head>
<body bgcolor="#FFFFFF">
<div align="center"><h1>Search Results:
HEADER

if (@found > 0)
{
    print scalar(@found);
}
else
{
    print 'No';
}
print ' match';
print 'es' if (@found != 1);
print " found.</h1></div><p>\n<hr>\n";

foreach my $out (@found)
{
    if ($cgi->param('graphics') eq 'on')
    {
	my $abbrev = $full_shorthand{$out->{'category'}};
	print "<table border=\"0\">\n<tr>\n<td><img src=\"../img/";
	print 'colors/' if ($cgi->param('colors') eq 'on');
	$out->{'category'} =~ s/ /_/g;
	print $out->{'category'};
	print ".gif\" hspace=\"5\" alt=\"$abbrev\"></td>\n<td>\n";
    }
    else
    {
	print "<i>$out->{'category'}</i><br>\n";
    }
    print "<b>$out->{'title'}</b><br>\n";
    print "$out->{'subtitle'}<br>\n";
    print "</td>\n</tr>\n</table>\n" if ($cgi->param('graphics') eq 'on');
    if ($out->{'type'} eq 'Character')
    {
	$out->{'fight'} =~ s/100/X/;
	print "$out->{'fight'} fighting<br>\n";
    }
    elsif ($out->{'type'} eq 'Site' |
	   $out->{'type'} eq 'Feng Shui Site' )
    {
	print "$out->{'power'} power, ";
	print "$out->{'body'} body<br>\n";
    }
    # leave out the Requires: for normal Feng Shui Sites
    unless (($out->{'cost'} == 0) &&
	    ($out->{'subtitle'} =~ /Feng Shui Site/)) 
    { 
	$out->{'cost'} =~ s/100/X/;          # 100-cost cards are X cost
	print_resources('Requires: ', "$out->{'requires'} $out->{'cost'}");
    }
    print_resources('Provides: ', $out->{'provides'});
    print_text_resources('', $out->{'text'})
	or print "<br>\n";
    print "<i>$out->{'flavor'}</i><br>\n";
    print_text_resources('Comment: ', $out->{'comments'});
    print "Art: $out->{'artist'}<br>\n";
    print "$out->{'edition'}, ";
    print "$out->{'rarity'}<br>\n<hr>\n";
}

# DEBUG
#my %to_short = &Cards::categories_short();
#use Data::Dumper;
#print (Dumper(\%to_short));

# Finish off our output page

print <<DONE;
<div align=center>
<table width="100%" border=0>
<tr><td>
</td>

<td align=center>
<p><table border="0" cellpadding="0" cellspacing="5"><tr><td><a href="../index.html">[ Home ]</a></td><td><a href="../index.html">[ Search ]</td><td><a href="mailto:searchmonkey\@chimpshack.org">[ Email ]</a></td></tr></table><br>
<address>CGI script by Will Wagner (wwagner\@io.com) / 15:41:57 / 27 May 2001</address></p></td>

<td valign=center>
</td>
</tr></table></div>
</body>
</html>

DONE

# Some subroutines to shorten this monster.
# First the conversion routine
sub convert_record
{
    my (@record) = @_;
    my %record;

    # In order, the fields are:
    # Type Edition Rarity Title Fight Provides Power Body Text Flavor
    # SubTitle Category Artist Comments Requires Cost
    $record{'type'} = $record[0];
    $record{'category'} = $record[1];
    $record{'title'} = $record[2];
    $record{'subtitle'} = $record[3];
    $record{'cost'} = $record[4];
    $record{'requires'} = $record[5];
    $record{'provides'} = $record[6];
    $record{'fight'} = $record[7];
    $record{'power'} = $record[8];
    $record{'body'} = $record[9];
    $record{'text'} = $record[10];
    $record{'flavor'} = $record[11];
    $record{'comments'} = $record[12];
    $record{'artist'} = $record[13];
    $record{'edition'} = $record[14];
    $record{'rarity'} = $record[15];
    return \%record;
}

sub generate_query 
{
    my ($cgi, @criteria) = @_;
    my ($query, $orderby);

    $query = 'SELECT type, cat as category, title, subtitle, cost, ' .
	            'requires, provides, fighting, power, body, text, ' .
	            'flavor, comments, artist, edition, rarity ' . 
             'FROM card, card_type, card_rarity, card_edition, card_cat ' .
             'WHERE card.card_type_id = card_type.card_type_id AND ' .
                   'card.card_cat_id = card_cat.card_cat_id AND ' .
                   'card.card_rarity_id = card_rarity.card_rarity_id AND ' .
                   'card.card_edition_id = card_edition.card_edition_id ';

    $query .= ' AND ' . join (' AND ', @criteria)
	if (@criteria > 0);
    $orderby = orderBy($cgi);
    $query .= " ORDER BY " . $orderby . 'title ';
    print STDERR $query;
    return $query;
}

# The text searching routines.
sub search_with_case
{
    my ($field, $bool, $elems, $dbh) = @_;
    my ($clause);
    my @elements = split /\s+/, $elems;

    if ($field eq "designators") {   
	# Although desig_split handles plurals,
	# it forces "and" queries, which are not desirable
	# @elements = map { &Cards::remove_s ($_) } @elements;
	my $desig = join " ", @elements;
	$desig = &Cards::desig_split ($desig);
	@elements = split " ", $desig;

	# Add spaces to force exact matches
	map { s/^(.*)$/ $1 / } @elements;
    }    
    # horrid hack to quotify strings
    @elements = map { "INSTR($field," . $dbh->quote($_) . ")" } @elements;
    if ($bool eq 'not') 
    { 
	$bool = 'and';
	@elements = map {$_ = 'not ' . $_;} @elements;
    }

    $clause = join " $bool ", @elements;
    $clause = "($clause)";
    return $clause;
}

sub search_no_case
{
    my ($field, $bool, $elems, $dbh) = @_;
    my ($clause);
    my @elements = split /\s+/, $elems;

    if ($field eq "designators") {   # we need to chop off trailing s's
	# Although desig_split handles plurals,
	# it forces "and" queries, which are not desirable
	# @elements = map { &Cards::remove_s ($_) } @elements;
	my $desig = join " ", @elements;

	$desig = &Cards::desig_split ($desig);
	@elements = split " ", $desig;

	# Add spaces to force exact matches
	map { s/^(.*)$/ $1 / } @elements;

    }

    # Handle the case where we've removed all invalid values, like
    # with a search for designator "Edge"
    if (@elements == 0) {
	@elements = (" ");
    }

    # horrid hack to quotify strings
    @elements = map { "$field like " . $dbh->quote("\%$_\%") } @elements;
    if ($bool eq 'not') 
    { 
	$bool = 'and';
	map {s/like/not like/} @elements;
    }

    $clause = join " $bool ", @elements;
    $clause = "($clause)";

    return $clause;
}

# Resource handling routines.
sub search_resource
{
    my ($field, $element) = @_;

    return 1 if ($field eq 'None' && $element eq '');
    my $tmp = $field;
    $tmp =~ s/Architects of the Flesh/f/;
    $tmp =~ s/Ascended/a/;
    $tmp =~ s/Dragons/d/;
    $tmp =~ s/Eaters of the Lotus/e/;
    $tmp =~ s/Four Monarchs/m/;
    $tmp =~ s/Guiding Hand/g/;
    $tmp =~ s/Jammers/j/;
    $tmp =~ s/Purist/p/;
    $tmp =~ s/Seven Masters/s/;
    $tmp =~ s/Chi/C/;
    $tmp =~ s/High Tech/H/;
    $tmp =~ s/Magic/M/;
    return 0 if (!($element =~ /$tmp/));
    return 1;
}

sub print_resources
{
    my ($name, $var) = @_;

    return 0 if ($var eq '' || $var eq ' ');
    &modify(\$var);
    if ($cgi->param('graphics') eq 'on') { 
      $var =~ s/([CHMadefgjmpsy])/<img alt="$symbol_cat->{$1}" src="..\/img\/$1.gif">/g;
    } else { 
      $var =~ s{([CHMadefgjmpsy])}{$symbol_cat->{$1}}g ;
    }

    $var =~ s/img\//img\/colors\//g
	if ($cgi->param('colors') eq 'on');
    print "$name$var<br>\n";
}

sub print_text_resources
{
    my ($name, $var) = @_;

    return 0 if ($var eq '' || $var eq ' ');

    $var =~ s/<(.+?)>/&lt;$1&gt;/g;                     # for HTML printing <>

    &modify(\$var);
    $var =~ s/\[([CHMadefgjmpsy])\]/<img src="..\/img\/$1.gif" alt="$symbol_cat->{$1}">/g
	if ($cgi->param('graphics') eq 'on');
    $var =~ s/img\//img\/colors\//g
	if ($cgi->param('colors') eq 'on');
    print "$name$var<br>\n";
}

# currently a no-op, to handle the updated db schema from shadowfisthub
sub modify {
    my ($var) = @_;

    return 0;
    
    $$var =~ s/(\[\w+?\])/$cat_symbol{$cat_shorthand{$1}}/g;
    return 0;
}

sub faction_where {
    my ($cat) = @_;
    if ($cat eq "Unaligned") {
       return "(requires LIKE '' AND 
                provides LIKE '')";
    }
    my %to_short = &Cards::categories_short();
    return "(requires LIKE '%" . $to_short{$cat} . "%' OR 
             provides LIKE '%" . $to_short{$cat} . "%')";
}

sub orderBy {
    my ($cgi) = @_;
    my $orderby = '';

    foreach my $sort qw (sort1 sort2 sort3) {
    	my $one_sort .= $cgi->param($sort . '_type') . ', '
            if ($cgi->param($sort . '_type') ne 'none');
	$one_sort =~ s/,/ desc,/
            if ($cgi->param($sort . '_dir') eq 'on');
       $orderby .= $one_sort;
    }
    return $orderby;
}
