#!/usr/bin/perl

##################################################################
# Author:  Brent Hughes
#
# Date:    11/8/03
#
# Program: rgetlinks.pl
#
# Purpose: This is a program to retrieve links from web pages
#          recursively. This may not seem terribly useful at
#          first, but by feeding the output to grep one can
#          easily acquire a list of files matching a certain
#          pattern. Automate lwp-download over the resulting 
#          list and you'll see my point. This method can easily
#          be used to aquire thousands of movie files and images
#          or whatever else you can think of.
#
# Bugs:    Please report any bugs to brent_hughes_@hotmail.com 
#          Also feel free to comment on the program's function 
#          and/or propose additional features.
#
# Version: 0.01
#
##################################################################

use warnings;
use strict;

package RGetLinks;

use LWP::UserAgent;
use HTML::LinkExtor;
use URI::URL;
use Getopt::Long;

$| = 1;

#################################################################
#  Main Program


# global data for this program
my $depth;
my %files;

# command line options
my $opt_depth = 2;

# retrieve command line options
my $options = GetOptions ("depth=i" => \$opt_depth);  # numeric

# acquire url from command line
my $url = shift;

# abort if the options are improperly formatted
if(!defined $url){ usage(); }

# program enters actual processing at this point
rgetlinks($url,$opt_depth);


#################################################################
#  Subroutines


# A routine to get links recursively 
sub rgetlinks
{
	my($url,$maxdepth) = @_;
	chomp($url);

	# initialize globals
	$depth = 0;
	%files = ();

	# mark the initial file
	$files{$url} = 1; 

	# print the initial file
	foreach(1..$depth) {print ' ';}
	print $url, "\n";	

	# descend
	rgetlinkshelper($url,$maxdepth);		
}

# A helper routine to get links recursively. 
# Interestingly, this constitutes a dynamic programming 
# implementation of breadth first search.
# BFS should be a more inclusive search over the type 
# of media one encounters on the Internet.
# For instance, under DFS, if one encounters a link at 
# depth three, it is added to the set of traversed links.
# Later on, that site may be seen again on depth two.
# But it cannot be traversed because it is already in 
# the list of open nodes (at least in this implementation).
# Choosing DP BFS prevents this problem. It also prevents
# the need for the relaxation step that would be necessary
# to allow the traversal of a node such as the one listed 
# above. The DP BFS spanning tree created by this program
# will be the hyperlink-MST of the site in question down 
# to the the depth specified.
sub rgetlinkshelper
{
	my($url,$maxdepth) = @_;

	# return if too deep or already been here
	if($depth >= $maxdepth)
	{   
		return;
	}
	else
	{
		# drop down a level 
		$depth++; 

		# retrieve all links (node expansion)
		my @links = getlinks($url);

		# retrieve relevant nodes and print
		# storing relevant nodes in a new list
		# do not revisit nodes!
		my @newlinks = ();
		foreach(@links)
		{
			if(not defined $files{$_})
			{
				# add the file to the hash (set mark)
				$files{$_} = 1;

				# print the file
				foreach(1..$depth) {print ' ';}
				print $_, "\n";		

				# add the file to the list of new links
				push(@newlinks, $_)
			}
		}

		# recursive step
		foreach(@newlinks){ rgetlinkshelper($_,$maxdepth); } 

		# pop up a level
		$depth--;
	}
}

# A routine to return all links from a URL
# This routine was borrowed almost verbatim from an example program.
# However, I did optimize it to only retrieve links from text/html
# files. The program was trying to retrieve links from large movie 
# files. Obviously, that didn't work too well. It also took up a lot 
# of computation time.

my @links = ();

sub getlinks
{
	my($url) = @_;  # for instance
	my $ua = new LWP::UserAgent;
	
	# Make the parser.  Unfortunately, we don't know the base yet
	# (it might be diffent from $url)
	@links = ();
	my $p = HTML::LinkExtor->new(\&callback);

	# Look at the header to determine what type of document we have
	my $headreq = HTTP::Request->new(HEAD => $url);
	my $headres = $ua->request($headreq); 
	my $type    = $headres->header('content-type');

	# only parse the document for links if it is a text or html document
	if(defined $type && $type =~ /text|html/)
	{
		# Request document and parse it as it arrives
		my $getreq = HTTP::Request->new(GET => $url);
		my $getres = $ua->request($getreq, sub{ $p->parse($_[0])});

		# Expand all URLs to absolute ones
		my $base = $getres->base;
		@links = map { $_ = url($_, $base)->abs; } @links;
	}
	
	# Return the links
	return @links;
}

# Set up a callback that collects links
sub callback {
	my($tag, %attr) = @_;

	return if $tag ne 'a';  # we only look closer at <a ...>
	push(@links, values %attr);
}

# A routine to provide instructions
sub usage
{
	# strip the progname with a regex
	my $progname = $0;
	$progname =~ s/(.*\\|.*\/)(.*)/$2/g;

	# show instructions
	print   "\nUsage:\n\t\t", 
		$progname, " [args] target-url > output-file\n\n",
		"Example:\n\t\t", 
		$progname, " --depth=3 http://www.perl.org\n\n";

	print   "Options\n", "=======\n", 
		
		"--depth\t\t", 
		"The maximum depth of links to traverse (default = 2)\n";

	exit();
}

__END__

=head1 NAME

  rgetlinks - A small program to recursively list hyperlinks in web pages

  version 0.01

=head2 USAGE SUMMARY

  rgetlinks [depth] URL
  rgetlinks --depth=3 http://www.perl.org

=head2 ABSTRACT

  This program follows hyperlinks in web pages and lists them recursively.
  Links are ouput with indentation showing their relative depth in the crawl.
  This program follows all links in the target document to the depth specified. 

=head2 DESCRIPTION

  This program was written to facilitate the automated download of web
  content. It is best used in conjunction with tools like grep and lwp-download.
  For instance, one can recursively crawl a web site with this program redirecting 
  the output to a text file. By using grep on the resultant file, one can easily
  create a shell script or batch file containing a series of lwp-dowload commands. 

=head1 SEE ALSO

  Other programs are being written to automate the second and third steps in the
  above procedure.

=head1 BUGS

  Please report any bugs to brent_hughes_[at]hotmail[dot]com.

  Also, feel free to comment on the program's coding or function.

  Also, let me know what other kinds of features you would like to see.

=head1 AUTHOR

  Brent Hughes

  brent_hughes_[at]hotmail[dot]com

=head2 COPYRIGHT AND LICENSE

  Copyright 2003 by Brent Hughes

  This program is free software. Do whatever you want with it. 

=cut
