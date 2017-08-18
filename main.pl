#! /usr/bin/perl
use warnings;
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;

sub scraper(){
	# Get list of files already downloaded
	my $dir = $_[0];
	my $url=$_[1];
	my @ls;

	unless(-d $dir){
		mkdir $dir;
	}
	opendir(DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
		next if ($file =~ /^\./);
		push(@ls, $file);
	}
	closedir(DIR);
	chdir $dir;


	# Initialise modules
	my $mech=WWW::Mechanize->new();
	$mech->get($url);
	my $tree=HTML::TreeBuilder::XPath->new();
	$tree->parse($mech->content);

	my $file;	# Working file
	my $skip = 0;	# To get out of nested loop
	my $localsize;	# File size on disk
	my $size;	# File size on server
	my $href=5; 	# Skip headers(Name,Last Modified, Size,
			# Description, Parent Directory
	my $workingnode;# XPath node for pre
	my @nodes = $tree->findnodes('/html/body');
	my @hrefnodes = $tree->findnodes('/html/body/pre/a');
	$workingnode = $nodes[0]->findvalue( 'pre');

	# Parse lines to get file sizes
	while($workingnode =~ s/(.+)\s+\d\d-\w{3}-\d{4} \d\d:\d\d\s+(\S+)//){

		#we must use href or we can't see long file names
		if($1 =~ /Parent Directory/){next;}
		$skip = 0;
		$file = $hrefnodes[$href++]->findvalue('@href');
		$size = $2;
		$file =~ s/^\s+(.+)/$1/;
		$file =~ s/(\S+)\s+$/$1/;

		if($size =~ /-/){ #directories
			&scraper("$dir/$file","$url/$file");
			chdir "..";
			next;
		}
		foreach(@ls){
			# Don't redownload anything we already have
			# unless it's bigger on the server as we may
			# have previously downloaded an incomplete file
			if($file =~ /$_$/){
				if($size=~s/M//){
					$size *= 1000000;
					$size -= 750000;
				}
				if($size=~s/k//){
					$size *= 1000;
					$size -= 750;
				}
				$localsize = -s $file;
				if($size>$localsize){
					`rm $file`;
					`rm $file.*`;
					#print "we already have $file, locally";
					#print "it is $localsize bytes and on";
					#print "the server it is $size bytes\n";
				}
				else{
					$skip++;
				}

			}
		}
		unless($skip){
			system"axel $url/$file";
		}
	}
}

my $dir;
my $url;

if(defined($ARGV[1]) && defined($ARGV[2])){
	$url = $ARGV[1];
	$dir = $ARGV[2];
}else{
	$dir = '/var/www/html/TempleOS/Videos';
	$url = "http://templeos.org/Videos";
}
&scraper($dir,$url);;
