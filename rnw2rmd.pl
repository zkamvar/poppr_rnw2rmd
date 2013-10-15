#!/usr/bin/perl

use warnings;
use strict;

my $line;
my $sec_count = 0;
my $sub_count = 0;
my $subsub_count = 0;
my $eq_count = 1;
my $box_indicator = 0;
my $tt_indicator = 0;

my %labels;
my @sections;


# Note: Things to change in the manual:
# REMOVE: H.df <- genind2df(H3N2) this chunk
# RENAME: nancy_example_show
# RbarD equation: remove substack.


open (RNW, "$ARGV[0]");


# Looping over the file first to collect labels of sections. 
while ($line = <RNW>){
	chomp $line;
	if ($line =~ m/^\\s\w+?tion\{(.+?)\}\s*\\label\{(.+?)\}/){
		$labels{$2} = $1;
		$sections[$sec_count++] = $1;
		# print "$labels{$2}\n";
	}
	
	if ($line =~ m/^\\label\{(.+?)\}$/){
			my @matches = ($line =~ m/^\\label\{(.+?)\}$/g);
			foreach (@matches){
				$labels{$_} = $eq_count++;
				# print "$labels{$_}\n";
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
	$line =~ s/\\emph\{(.+?)\}/*$1*/g;
	$line =~ s/\\textbf\{(.+?)\}/**$1**/g;
	$line =~ s/\\texttt\{(.+?)\}/`$1`/g;
	$line =~ s/\\textsc\{(.+?)\}/**$1**/g;
	$line =~ s/(hide)/'$1'/g;

	# URL handling.
	$line =~ s/\\url\{(.+?)\}/[$1]($1)/g;

	# Comments.
	$line =~ s/^%(.+?)$/<!--$1-->/;

	# Removing useless items.
	$line =~ s/\\(\{|\_|\$|\%|\&|\})/$1/g;
	$line =~ s/\\\\//g;
	$line =~ s/\\tab//g;
	$line =~ s/^\s*?\\((begin)|(end)|(newpage)).*?$//;
	$line =~ s/^\\setkeys\{Gin\}.+?$//;
	$line =~ s/\\hspace.+?$//;

	# Sections
	if ($line =~ s/\\section\{(.+?)\}\s*\\label\{(.+?)\}/# $1/){
		#close (RMD);
		my $section = $2;
		#open (RMD, ">$section.Rmd");
		print "\nSection: $1\tFile: $section.Rmd\n"
	}
	$line =~ s/\\subsection\{(.+?)\}/## $1/;
	$line =~ s/\\subsubsection\{(.+?)\}/### $1/;

	# Section Labels
	$line =~ s/(^\#+?\s)(.+?)\\label\{(.+?)\}/$1 \<a id\="$3"\>\<\/a\>$2/;

	# Other Labels	
	$line =~ s/^\\label\{(.+?)\}$/\<a id\="$1"\>\<\/a\>\$\$/g;
	$line =~ s/\\label\{(.+?)\}/\<a id\="$1"\>\<\/a\>/;

	# Formatting references so that they actually link to the sections in html.
	if ($line =~ s/\\ref\{(.+?)\}/[$labels{$1}](#$1)/){
		my @matches = ($line =~ m/\\ref\{(.+?)\}/g);
		for (@matches){
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

	# Footnotes become hover items.
	$line =~ s/\\footnote{(.+?)}/\[\\\*\]\(\/ "$1"\)/g;

	# style options
	$line =~ s/(\\large)|(\\footnotesize)|(\\centering)//g;
	$line =~ s/^\s*\\caption\{(.+?)\}$/\> $1\n/;

	# Image handling. 
	if($line =~ m/^\s*\\includegraphics\{(.+?)\}/){
		my $image = $1;
		if ($image =~ m/png$/){
			$line =~ s/^\s*\\includegraphics\{(.+?)\}/\<img src="$1" style\="width\: 500px\;"\>\<\/img\>/;
		} else {
			$line =~ s/^\s*\\includegraphics\{(.+?)\}/\<img src="$1.png" style\="width\: 500px\;"\>\<\/img\>/;
		}
	}

	# Output handling. No messages printed.
	$line =~ s/(echo\s*\=\s*FALSE)/$1\, message \= FALSE/;

	# Information boxes becoming block quotes.
	if ($box_indicator == 0){
		if ($line =~ m/\\fcolorbox/){
			$box_indicator = 1;
		}
		else{
			print RMD "$line\n";
		}
	} elsif ($line =~ m/^\s*\}$/) {
		$box_indicator = 0;
	} else {
		print RMD "> $line\n";
	}
	
}

close (RNW);
close (RMD);





