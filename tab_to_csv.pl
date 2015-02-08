use Text::xSV;
my $csv = new Text::xSV;

while (<>) {
  chomp;
  s/\r//g;
  @values = split(/\t/);
  $csv->print_row(@values);
}
