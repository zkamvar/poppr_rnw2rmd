#!/usr/bin/perl

#==============================================================================#
# Program to convert Sweave (*.Rnw) formatted files to Rmarkdown (*Rmd).
# 
# All figures and bibtex files need to be in the same directory. 
#==============================================================================#

use warnings;
use strict;

if (!$ARGV[0]){
	&usage();
	exit -1
}

my $line;
my @out = split /\./, $ARGV[0];

# Counters for labels.
my $sec_count = 0; # Sections
my $eq_count = 1;  # Equations

# Indicators for printing
my $latex_indicator = 1; # latex preamble
my $box_indicator = 0;   # boxquotes
my $tt_indicator = 0;    # multiline teletype
my $bib = "";

my %labels;
my @sections;

open (RNW, "$ARGV[0]");

# Looping over the file first to collect labels of sections. 
while ($line = <RNW>){
	chomp $line;
	if ($line =~ m/^\\s\w+?tion\{(.+?)\}\s*\\label\{(.+?)\}/){
		$labels{$2} = $1;
		$sections[$sec_count++] = $2;
		# print "$labels{$sections[$sec_count - 1]}: $sections[$sec_count - 1]\n";
	}
	
	if ($line =~ m/^\\label\{(.+?)\}$/){
			my @matches = ($line =~ m/^\\label\{(.+?)\}$/g);
			foreach (@matches){
				$labels{$_} = $eq_count++;
				# print "$labels{$_}\n";
			}
	}
	if ($line =~ m/\\bibliography\{(.+?)\}/){
		$bib = $1;
		if ($bib !~ m/\.bib$/){
			$bib = $bib.".bib";
		}
	}
}

close (RNW);
open (RNW, "$ARGV[0]");
open (RMD, ">$out[0].Rmd");

while ($line = <RNW>){
	chomp $line;

	# Preamble
	if ($line =~ s/\\title\{(.+?)\}$/$1\n=======\n/){
		$latex_indicator = 0;
	}
	if ($line =~ m/\\author/){
		$line = 'Zhian N. Kamvar<sup>1</sup> and Niklaus J. Gr&uuml;nwald<sup>1,2</sup>'."\n\n".
		'1) Department of Botany and Plant Pathology, Oregon State University, Corvallis, OR'."\t".
		'2) Horticultural Crops Research Laboratory, USDA-ARS, Corvallis, OR';
	}
	if ($line =~ s/\\begin\{abstract\}/# Abstract/){
		$latex_indicator = 0;
	}
	if ($line =~ s/\\end\{abstract\}//){
		$line = '```{r, echo = FALSE, message = FALSE}'."\n".
		'library(knitcitations)'."\n".
		'bib <- read.bibtex("'.$bib.'")'."\n".
		'```';
	}
	$line =~ s/\\hyperset.+?$/***/;
	if ($line =~ m/\\tableofcontents/){
		print RMD "# Table of contents\n";
		foreach my $item (@sections){
			# The labels are based on a hierarchy of colons sec:subsec:subsubsec
			my @hierarchy = ($item =~ m/\:/g);
			my $hierarchy_num = (@hierarchy);
			my $title = $labels{$item};
			$title =~ s/\\(\{|\})/$1/g;
			if ($hierarchy_num == 0){
				print RMD " - <h3>[$title](#$item)<\/h3>\n";
			} elsif ($hierarchy_num == 1){
				print RMD "    - [$title](#$item)\n";
			} elsif ($hierarchy_num == 2){
				print RMD "        - [$title](#$item)\n";
			}
			
		}
		print RMD "\n***\n";
		$line = "";
	}

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
	if ($line =~ s/\\section\{(.+?)\}\s*\\label\{(.+?)\}/# \<a id\="$2"\>\<\/a\>$1/){
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
	$line =~ s/^\s*\\item\{(.+?)\}/ - $1/;
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

	# Citations
	$line =~ s/\\cite\{(.+?)\}/`r citep(bib[["$1"]])`/g;

	# Bibliography
	if ($line =~ m/\\bibliography\{(.+?)\}/){
		$line = 
		'# Bibliography'."\n".
		'```{r, echo = FALSE, results = "asis"}'."\n".
		'bibliography("html")'."\n".
		'```';
	}

	# Information boxes becoming block quotes.
	if ($latex_indicator == 0){
		if ($line =~ m/\n=======\n/){
			$latex_indicator = 1;
		}
		if ($box_indicator == 0){
			if ($line =~ m/\\fcolorbox/){
				$box_indicator = 1;
			} else {
				print RMD "$line\n";
			}
		} elsif ($line =~ m/^\s*\}$/) {
			$box_indicator = 0;
		} else {
			print RMD "> $line\n";
		}
	}	
}

close (RNW);
close (RMD);


sub usage {
	print STDERR "\n$0 Version 0.0.1, Copyright (C) Zhian N. Kamvar \n";
	print STDERR "$0 software comes with no warranty\n";
	print STDERR <<EOF;
	NAME
	$0 converts Sweave documents to Rmarkdown.
	USAGE
	$0 <infile.Rnw>
	OUTPUT
	<outfile.Rmd>

EOF
}


