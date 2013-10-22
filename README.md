Rnw 2 Rmd
==========

This perl script is explicitly written for the purposes of converting
[poppr's](https://github.com/poppr/poppr) Sweave (\*.Rmd) formatted [vignette](https://github.com/poppr/poppr/blob/master/vignettes/poppr_manual.Rnw)
to an Rmarkdown (\*.Rmd) formatted file.

Usage:

    ./rnw2rmd.pl poppr_manual.Rnw

Your output will be `poppr_manual.Rmd`. The R command to create the HTML and md
files (provided you have the required packages listed below) is:
    R -e 'library(knitr); knit("poppr_manual.Rmd")'

Required packages:
 - knitr
 - knitcitations


While this will convert the file without any of the necessary image files for
the vignette, producing an html version is greatly enhanced if the images
located in the [vignettes directory](https://github.com/poppr/poppr/tree/master/vignettes)
were in the same directory as your new .Rmd file. The [bibtex file](https://github.com/poppr/poppr/blob/master/vignettes/poppr_man.bib)
is also necessary as this script inserts a call to the [knitcitations](https://github.com/cboettig/knitcitations)
package, allowing a bibliography and active links to be generated.

***

Feel free to modify this script to convert your Sweave document into an Rmarkdown
document.
