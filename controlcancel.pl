#!/usr/bin/perl

#
# controlcancel.pl v0.0.0
# Author: Mikael O. Bonnier, mikael.bonnier@gmail.com, http://www.df.lth.se.orbin.se/~mikaelb/
# Copyright (C) 2007 by Mikael O. Bonnier, Lund, Sweden.
# License: GNU GPL v3 or later, http://www.gnu.org/licenses/gpl-3.0.txt
# Commercial licenses are available.
#
# Purpose: To store control.cancel messages for a group on an NNTP-server 
#    in textfiles.
# Motive: Sometimes messages are canceled against the will of the sender.
#    In order to investigate this one needs the control.cancel message but they
#    normally can be difficult to find.
# Example: http://www.df.lth.se.orbin.se/~mikaelb/control.cancel/
# Installation: Adjust cfg-block in this file. Create an empty file <group>_0000.txt in
# the <dir>. Run using crontab each night, e.g. 
# 15 4 * * * cd <installdir>; <perldir>/perl ./controlcancel.pl &
# Ampersand in crontab makes the program uninterruptible. (Symbols in <> should be
# exchanged for real values.)
#

use strict;
use News::NNTPClient; # If locally installed, use NNTPClient

# <cfg>
my $NNTPServer = "news.lth.se";
my $group = "swnet.politik";
my $dir = "../public_html/control.cancel/";
my $delay = 0; # seconds
# </cfg>

my $c = new News::NNTPClient($NNTPServer);
my ($first, $last) = $c->group("control.cancel");

opendir CTRLCAN, $dir;
my @files = grep /^$group\_(\d+)\.txt$/, readdir CTRLCAN;
my $max = 0;
foreach $_ (@files) {
	$_ =~ m/(\d+)\.txt$/;
	if($1 > $max) {
		$max = $1;
	}
}

my $inFile = sprintf "$group\_%04d.txt", $max;
open IN, '<', $dir . $inFile;
my $line;
read IN, $line, 80;
close IN;
$line =~ m/\$last=(\d+)/;
$first = $1 + 1 if $1;

my $file = sprintf "$group\_%04d.txt", $max+1;
open OUT, '>', $dir . $file;
print OUT "\$first=$first, \$last=$last\n";
my $starttime = time;
print OUT "\$starttime=$starttime\n\n";

for(; $last >= $first; --$last) {
	my $head = join('', $c->head($last));
	if($head =~ m/^Newsgroups:.*[\s|,]+$group.*$/m) {
		print OUT $c->article($last);
		print OUT "\n\n";
	}
       sleep $delay;
}

my $stoptime = time;
print OUT "\n\$stoptime=$stoptime\n";
print OUT "\$elapsed=" . ($stoptime-$starttime) . " s\n";
close OUT;

__END__ 
