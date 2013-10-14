#!/usr/bin/perl

use warnings;
use strict;

my $line;
my $sec_count = 0;
my $sub_count = 0;
my $subsub_count = 0;

open (RNW, "$ARGV[0]");

my @out = split /\./, $ARGV[0];

open (RMD, ">$out[0].Rmd");

while ($line = <RNW>){
	chomp $line;

	# Quotations.
	$line =~ s/``(.+?)\"/"$1"/g;

	# Changing code chunks
	$line =~ s/^\<\<(.*?)\>\>\=*?$/```{r, $1}/;
	$line =~ s/^\@$/```/;

	# Changing text formatting, Itallic, Bold, and Teletype
	$line =~ s/\\textit\{(.+?)\}/*$1*/g;
	$line =~ s/\\textbf\{(.+?)\}/**$1**/g;
	$line =~ s/\\texttt\{(.+?)\}/`$1`/g;

	# URL handling.
	$line =~ s/\\url\{(.+?)\}/[$1]($1)/g;

	# Comments.
	$line =~ s/^%(.+?)$/<!--$1-->/;

	# Sections
	if ($line =~ s/\\section\{(.+?)\}/# $1/){
		close (RMD);
		my @section = split /\s/, $1;
		open (RMD, ">$out[0]_$section[0].Rmd");
	}
	$line =~ s/\\subsection\{(.+?)\}/## $1/;
	$line =~ s/\\subsubsection\{(.+?)\}/### $1/;
	$line =~ s/\\label.+?$//;

	# Removing useless items.
	$line =~ s/\\(\{|\_|\$|\%|\&|\})/$1/g;
	$line =~ s/\\\\//g;
	$line =~ s/\\tab//g;
	$line =~ s/^\s*?\\((begin)|(end)|(newpage)).*?$//;

	# Dealing with itemize.
	$line =~ s/^\s*\\item(.+?)$/ -$1/;
	$line =~ s/^\s*\-\s*\[\s*(\\\w+?\b)*(\s*.+?)\](.+?)/ - **$2**$3/;

	# Equations.
	$line =~ s/\$\\geq\$/&ge;/g;
	$line =~ s/\\beq/\$\$/;
	$line =~ s/\\eeq/\$\$/;
	$line =~ s/\\bar r_d/\\bar{r}_d/g;

	# Footnotes.
	$line =~ s/\\footnote{(.+?)}/\[\\\*\]\(\/ "$1"\)/g;

	print RMD "$line\n";
}

close (RNW);
close (RMD);