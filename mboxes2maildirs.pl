#!/usr/bin/perl
# $Header$
use strict;
use warnings;
my $tmpdir = $ARGV[0];
my $mboxdir = $ARGV[1];
my $maildirdir = $ARGV[2];
unless (-d $tmpdir  && -O $tmpdir) {
	die "mkdir tmpdir first";
}
unless (-d $mboxdir && -O $mboxdir) {
	die "mkdir mboxdir first and populate it with mboxes";
}
unless (-d $maildirdir && -O $maildirdir) {
	die "mkdir maildirdir first";
}
die "usage: mboxes2maildirs.pl tmpdir mboxdir maildirdir" unless
    (defined($tmpdir) && defined($mboxdir) &&
    defined($maildirdir));
$mboxdir =~ s#/$##;
$maildirdir =~ s#/$##;
my @mbox_files = <$mboxdir/*>;
my @maildirs;

# Split mbox into separate files.
foreach my $file (@mbox_files) {
	my ($lines_handle, $maildir_name, $i);
	$maildir_name = $file;
	$maildir_name =~ s#^.*/(.*)$#$1#;
	push @maildirs, $maildir_name;
	my $count = 0;
	my @lines = ();
	open my $fh, '<', $file or die;
	die "mbox not owned by you or not a text file"
	    unless (-O $file && -T $file);
	mkdir "$tmpdir/$maildir_name", 0700 or die;
	open $lines_handle, '>', "$tmpdir/$maildir_name/$count" or die;
	my $curr = "";
	my $prev = "";
	while ($curr = <$fh>) {
		if ($curr =~ /^From/ && $prev =~ /^$/) {
			close $lines_handle or warn;
			my $msg_file = "$tmpdir/$maildir_name/$count"; 
			open $lines_handle, '>',
			    "$tmpdir/$maildir_name/$count" or die;
			$count++;
		}
		print $lines_handle $curr;
		$prev = $curr;
	}
}

# Create maildirs from individual messages.
foreach my $dir (@maildirs) {
	my @files = glob "$tmpdir/$dir/*";
	foreach my $file (@files) {
		system "/usr/libexec/mail.maildir $maildirdir/$dir <$file";
	}
}
