#! /usr/local/bin/perl

use strict;
use warnings;

while (<>) {
    # 0x93 (147) and 0x94 (148) are "smart" quotes
    s/[\x93\x94]/"/g;

    # 0x91 (145) and 0x92 (146) are "smart" singlequotes
    s/[\x91\x92]/'/g;

    # 0x96 (150) and 0x97 (151) are emdashes
    s/[\x96\x97]/--/g;

    # 0x85 (133) is an ellipsis
    s/\x85/.../g;

    print;
}
