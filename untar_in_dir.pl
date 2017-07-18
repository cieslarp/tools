#!/usr/local/bin/perl

while (my $dir = <*>) {
	next unless -d $dir;
	next if $dir =~ /^\./;

	print "Dir:($dir)\n";
	chdir($dir);
	while (my $tar = <*all.tar*>) {
		print "Tar:($tar)\n";
		system("tar zxvf $tar");
	}
	chdir("..");
}
