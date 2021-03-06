#!/usr/local/bin/perl

use lib ("/home/chimpsha/lib");
use Cards;


print <<HEADER;
Content-type: text/html

<html>
<head>
<link rel="made" href="mailto:searchmonkeyatchimpshackdotorg">
<title>Search the Shadowfist card database</title>
<base target="_top">
</head>
<body bgcolor="#FFFFFF" background="pics/texture.gif">

<div align=center>
<h1>Search the Shadowfist<sup><font size=-1>TM</font></sup>
Database</h1>
</div>
<div align=center>
<table border=1>
<tr>
<td colspan=2>
<form method="post" action="card_search.cgi">
Card type: 
<select name="type">

HEADER

&Cards::option_set('type');

print <<EOB;

</select>
Category/Faction:
<select name="category">
EOB

&Cards::option_set('cat');

print <<EOB;
</select><br>
</td>
</tr>
<tr>
<td>
<table border=0>
<tr>
<td colspan=3><font size=+1>Card Text:</font></td>
</tr>
<tr>
<td>Title:</td>
<td><input type="text" name="title" size=20 maxlength=40></td>
<td>
<select name="title_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Subtitle:</td>
<td><input type="text" name="subtitle" size=20 maxlength=40></td>
<td>
<select name="subtitle_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Designator:</td>
<td><input type="text" name="designator" size=20 maxlength=40></td>
<td>
<select name="designator_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Text:</td>
<td><input type="text" name="text" size=20 maxlength=40></td>
<td>
<select name="text_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Flavor Text:</td>
<td><input type="text" name="flavor" size=20 maxlength=40></td>
<td>
<select name="flavor_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Comments:</td>
<td><input type="text" name="comments" size=20 maxlength=40></td>
<td>
<select name="comments_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
<tr>
<td>Artist:</td>
<td><input type="text" name="artist" size=20 maxlength=40></td>
<td>
<select name="artist_bool">
<option selected>and
<option>or
<option>not
</select>
</td>
</tr>
</table>
</td>

<td valign="top">
<table border=0>
<tr>
<td><font size=+1>Play cost:</font></td>
<td><input type="text" name="cost" size=10 maxlength=20><br></td>
</tr>
<tr>
<td colspan="2"><font size=+1>Resources:</font></td>
</tr>
<tr>
<td>Required:</td>
<td>
<select name="requires">
<option selected>Any
<option value="">None
<option value="f">Architects of the Flesh
<option value="a">Ascended
<option value="d">Dragons
<option value="e">Eaters of the Lotus
<option value="m">Four Monarchs
<option value="g">Guiding Hand
<option value="j">Jammers
<option value="p">Purists
<option value="s">Seven Masters
<option value="C">Chi
<option value="H">High Tech
<option value="M">Magic
</select>
</td>
</tr>
<tr>
<td>Generated:</td>
<td>
<select name="provides">
<option selected>Any
<option value="">None
<option value="f">Architects of the Flesh
<option value="a">Ascended
<option value="d">Dragons
<option value="e">Eaters of the Lotus
<option value="m">Four Monarchs
<option value="g">Guiding Hand
<option value="j">Jammers
<option value="p">Purists
<option value="s">Seven Masters
<option value="C">Chi
<option value="H">High Tech
<option value="M">Magic
</select>
</td>
</tr>
<tr>
<td colspan="2"><font size=+1>Characters:</font></td>
</tr>
<tr>
<td>Fighting score:</td>
<td><input type="text" name="fighting" size=10 maxlength=20></td>
</tr>
<tr>
<td colspan="2"><font size=+1>Sites:</font></td>
</tr>
<tr>
<td>Power:</td>
<td><input type="text" name="power" size=10 maxlength=20></td>
</tr>
<tr>
<td>Body:</td>
<td><input type="text" name="body" size=10 maxlength=20></td>
</tr>
</table>
</td>
</tr>
<tr>
<td colspan=2>
<font size=+1>Set Information:</font>
Card edition:
<select name="edition">
EOB

&Cards::option_set('edition');

print <<EOB;
</select>
Card rarity:
<select name="rarity">
EOB

&Cards::option_set('rarity');

print <<EOB;
</select>
</td>
</tr>
<tr>
<td colspan=2>
<font size=+1>Sorting:</font>
Sort by:
<select name="sort_type">
<option selected>No sorting
<option value="cat">Category
<option>Title
<option>Subtitle
<option>Artist
<option value="cost">Play Cost
<option value="fighting">Fighting Score
<option>Power
<option>Body
<option value="card_edition.seq">Card Edition
<option value="card_rarity.seq">Rarity
</select>
<input type="checkbox" name="sort_dir">Reverse Sort
</td>
</tr>
</table>

<input type="checkbox" name="case_sense">Case-sensitive Searching
<input type="checkbox" name="graphics" checked>Graphics in Output
<input type="checkbox" name="colors" checked>Colored icons<br>
<input type="submit"> <input type="reset">
</form>
<div align="left">
<p>
16 Feb 2006: Completed restore from shadowfisthub sql server.
Added refined designator search, standardized all abbreviations
for faction and talent icons in the database.  Fixed splitting
of special designators (Gun, Sword, Buro, Arcano).  Many thanks
to all who submitted bug reports, new graphics files, etc.
<p>
Updated 7 Mar 2005: Added Two-Fisted Tales (this actually happened
back in November).  Corrected a card error on Invisi-Ray. 
<p>

<br>
</div>

<hr><br>

<h1>To use this search form:</h1></div>

<p>Only fill out what you need to specify your search. As it is when you
first see it, it will return every card in the database, for around 500K
of data (please don't do this; go to one of Randall's
<a href="http://www.gummiwisdom.com/fist/lists.html">lists</a> for
that).  For checklists, try <a href=
"http://netherworld.chimpshack.org/sf_cardlist.html">Stefan's
lists</a> or <a
href="http://www.crystalkeep.com/tcg/shadowfist/lists/index.html">Crystal
Keep</a>.  Here are some <a href="searching.html">instructions</a>.
Play with it a little if you're having trouble; it's not too hard to
figure out. If you're
<i>really</i> stumped, fire me some
<a href="mailto:searchmonkey\@chimpshack.org">mail</a>.</p>

<p> Available for download: <a href="chimpsha_fistdb.csv">csv</a>, 
<a href="chimpsha_fistdb.xml">XML</a>, and 
<a href="chimpsha_fistdb.sql">mysqldump file</a> (366k).  The 
latter contains schema, data, etc.  I use a few <a 
href="conventions.html">conventions</a> in the raw data which you
can/should note.</p>

<p>Please send me <a href="mailto:searchmonkey\@chimpshack.org">feedback</a> 
if you'd like to see new features, or to comment on existing
ones.  You can embarrass me and call me out on the public
Shadowfist forums, too. </p>

<p>The disclaimer: <a href="http://www.shadowfist.com/">Z-Man Games</a>
owns all the information contained in this database, as well as the
faction graphics, and anything else having to do with the Shadowfist
game.  This search engine is provided by the author as a convenience
for players, and is not affiliated with Z-Man Games in any way.  The
information is as complete and correct as humanly possible; however
some errors may remain, and as such the author makes no guarantees
about the correctness of the data contained herein.  Any damage or
loss or flamewar resulting from possible inaccuracy of this data is
not the fault of the author.</p>

<p>

To do: >, < searches on numeric values, and backending the stats page
into mysql as well.  Update xml dump.  Create an option to suppress
extras, so you can make customizable checklists.  Fix data
representation of feng shui sites, redundant cards.  

<p>
I strive to make the Shadowfist card database bug-free but if i've
missed anything, please <a
href="mailto:searchmonkey\@chimpshack.org">mail me</a>. -ericlui
</p>
<hr><br>

<div align=center>
<table width="100%" border=0>
<tr><td>

<td align=center>
<table border="0" cellspacing="5" cellpadding="0"><tr><td><a href="/index.html">[ Home ]</a></td><td><a href="mailto:searchmonkey\@chimpshack.org">[ Email ]</a></td></tr></table>
<!--#config timefmt="%T / %d %b %Y"-->
<address><p>
Form by Will Wagner (wwagner at io dot com)</p></address>

<address><p>
Maintained by Eric Lui (searchmonkey at chimpshack dot org)</p></address></td></td>

<td valign=center>
</tr></table></div>

</body>
</html>

EOB


