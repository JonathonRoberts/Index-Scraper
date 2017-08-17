#! /usr/bin/perl

use warnings;
use strict;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;

sub scraper(){
	# Get files we've already downloaded
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


	my $mech=WWW::Mechanize->new();
	$mech->get($url);

	my $tree=HTML::TreeBuilder::XPath->new();

	$tree->parse($mech->content);

	my @nodes = $tree->findnodes('/html/body');

	my $file;
	my $skip = 0;
	my $localsize;
	my $size;
	my $workingnode;
	my @hrefnodes = $tree->findnodes('/html/body/pre/a');
	my $href=5;

	for my $node (@nodes) {

		$workingnode = $node->findvalue( 'pre');
		# Parse line
		for(my $i = 0;$i<1;$i++){#Skip parent directory
			$workingnode =~ s/(.+)\s+\d\d-\w{3}-\d{4} \d\d:\d\d\s+(\S+)//;
		}
		while($workingnode =~ s/(.+)\s+\d\d-\w{3}-\d{4} \d\d:\d\d\s+(\S+)//){

			$skip = 0;
			#we must use href or we can't see long file names
			$file = $hrefnodes[$href++]->findvalue('@href');
			$size = $2;
			$file =~ s/^\s+(.+)/$1/;
			$file =~ s/(\S+)\s+$/$1/;
			#if($file=~/Name/){next;}
			#if($file=~/Parent Directory/){next;}

			if($size =~ /-/){ #directories
				&scraper("$dir/$file","$url/$file");
				chdir $dir;
				$skip++;
				next;
			}
			foreach(@ls){
				#don't redownload anything we already have
				#unless it's bigger on the server
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
						#print "we already have $file,";
						#print "locally it is $localsize bytes";
						#print "and on the server it is";
						#print "$size bytes\n";
					}
					else{
						$skip++;
					}

				}
			}
			unless($skip){
				'axel $url/$file';
			}
		}
	}
}
my $dir = '/var/www/html/TempleOS/Videos';
my $url = "http://templeos.org/Videos";
&scraper($dir,$url);;
