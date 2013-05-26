GameOfLife-perl
===============

Conway's Game of Life — Perl + TK

A nice little program of blinks and bleeps, Methuselahs and gliders. This one looks all graphical thanks to the [Perl/TK](http://search.cpan.org/~srezic/Tk-804.031/Tk.pod) module, so you need to have that installed:

    cpan install Tk

Great news! Now you have a fairly awkward windowing system installed that Perl can latch onto. I'll be honest: Perl does its best work when it's regexp-ing text files, and I don't see myself making too much further use of Perl::Tk in my designs.

Anyway, run the program as:

<code>perl gameoflife <i>rlefile</i>

where _`rlefile`_ is a text file in run-length encoded format. You can find lots and lots of RLE files at http://www.conwaylife.com/patterns/.
