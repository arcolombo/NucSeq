#!/usr/bin/env perl
# ------------------------------------------------------------------------------
##The MIT License (MIT)
##
##Copyright (c) 2015 Jordi Abante
##
##Permission is hereby granted, free of charge, to any person obtaining a copy
##of this software and associated documentation files (the "Software"), to deal
##in the Software without restriction, including without limitation the rights
##to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##copies of the Software, and to permit persons to whom the Software is
##furnished to do so, subject to the following conditions:
##
##The above copyright notice and this permission notice shall be included in all
##copies or substantial portions of the Software.
##
##THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##SOFTWARE.
# ------------------------------------------------------------------------------

# Libraries
use strict;
use Compress::Zlib;

# Inputs
my $scriptname = $0;
my $chr_gz = @ARGV[0];
my $kernel_file = @ARGV[1];
my $bandwidth = @ARGV[2];

# Variables
my $total = 0;
my $length = 0;
my $coverage = 0;

# Open chr_file
my $chr_fh = gzopen($chr_gz, "rb") or die("can't open file:$!");
my @chr_file=();
while ($chr_fh->gzreadline(my $chr) > 0)  
{
    push @chr_file,$chr;
}
# Close gz file
$chr_fh->gzclose();

# Read in Kernel
open ( my $kernel_fh,$kernel_file) or die ("can't open file:$!");
my @kernel_file=();
foreach my $value (<$kernel_fh>)
{
    push @kernel_file,$value;
}

## Check total number of fragments
foreach my $line (@chr_file)
{
    chomp($line);
    my @line = split(/\s+/, $line);
    my $chr=$line[0];
    my $pos=$line[1] ;
    my $counts=$line[2];
    $total += $counts;
    $length = $pos;
}

# Estimation of average coverage per base
$coverage = $total / $length;

## Apply kernel and normalize
# Loop through the file
foreach my $line (@chr_file)
{
    chomp($line);
    my @line = split(/\s+/, $line);
    my $chr=$line[0];
    my $pos=$line[1] ;
    my $counts=$line[2];
    my $i= $pos - int $bandwidth/2;
    foreach my $kernel_value (@kernel_file)
    {
        chomp $kernel_value;
        my $score= $counts * $kernel_value / $coverage;
        if (($i>=1)&&($score>0)){
            print "$chr\t$i\t$score\n";
        }
        $i++;
    }
}

