#!/usr/bin/perl

use warnings;
use strict;

my $line;
my $sec_count = 0;
my $sub_count = 0;
my $subsub_count = 0;
my $eq_count = 1;

my %labels;

open (RNW, "$ARGV[0]");

while ($line = <RNW>){
	chomp $line;
	if ($line =~ m/^\\s\w+?tion\{(.+?)\}\s*\\label\{(.+?)\}/){
		$labels{$2} = $1;
		print "$labels{$2}\n";
	}
	
	if ($line =~ m/^\\label\{(.+?)\}$/){
			my @matches = ($line =~ m/^\\label\{(.+?)\}$/g);
			#$line =~ s/^\\label\{(.+?)\}$/\<a id\="$1"\>\<\/a\>\$\$/g;
			foreach (@matches){
				$labels{$_} = $eq_count++;
				print "$labels{$_}\n";
			}
	}
}

close (RNW);
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

	# Removing useless items.
	$line =~ s/\\(\{|\_|\$|\%|\&|\})/$1/g;
	$line =~ s/\\\\//g;
	$line =~ s/\\tab//g;
	$line =~ s/^\s*?\\((begin)|(end)|(newpage)).*?$//;

	# Sections
	if ($line =~ s/\\section\{(.+?)\}/# $1/){
		close (RMD);
		my @section = split /\s/, $1;
		open (RMD, ">$out[0]_$section[0].Rmd");
		print "\nSection: $1\n"
	}
	$line =~ s/\\subsection\{(.+?)\}/## $1/;
	$line =~ s/\\subsubsection\{(.+?)\}/### $1/;
	$line =~ s/(^\#+?\s)(.+?)\\label\{(.+?)\}/$1 \<a id\="$3"\>\<\/a\>$2/;
	
	$line =~ s/^\\label\{(.+?)\}$/\<a id\="$1"\>\<\/a\>\$\$/g;
	$line =~ s/\\label\{(.+?)\}/\<a id\="$1"\>\<\/a\>/;

	if ($line =~ s/\\ref\{(.+?)\}/[$labels{$1}](#$1)/){
		my @matches = ($line =~ m/\\ref\{(.+?)\}/g);
		foreach (@matches){
			$line =~ s/\\ref\{($_)\}/[$labels{$1}](#$1)/g;
		}
	}

	# Dealing with itemize.
	$line =~ s/^\s*\\item(.+?)$/ -$1/;
	$line =~ s/^\s*\-\s*\[\s*(\\\w+?\b)*\s*(.+?)\s*\](.+?)/ - **$2**$3/;

	# Equations.
	$line =~ s/\$\\geq\$/&ge;/g;
	$line =~ s/\\beq//;
	$line =~ s/\\eeq/\$\$/;
	$line =~ s/\\bar r_d/\\bar{r}_d/g;

	# Footnotes.
	$line =~ s/\\footnote{(.+?)}/\[\\\*\]\(\/ "$1"\)/g;

	print RMD "$line\n";
}

close (RNW);
close (RMD);





