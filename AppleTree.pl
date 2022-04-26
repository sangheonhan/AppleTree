use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Copy qw( move );

use constant APPLETREE_ADDON_LIST 	=> 'AppleTreeAddonList.txt';
use constant APPLETREE_CURRENT		=> 'appletree.zip';
use constant DROPBOX_PUBLIC		=> 'C:\Users\bookworm\Dropbox\Public';

unlink APPLETREE_CURRENT;

my @addons = read_all_addon_list();
my @exclude_addons = read_addon_list('AppleTreeExcludeAddonList.txt'); 

my %exclude = map {($_, 1)} @exclude_addons;
@addons = grep {!$exclude{$_}} @addons;

my $zip = Archive::Zip->new();
my $addon;
foreach $addon ( @addons ) {
    unless ( -e $addon && -e "$addon/$addon.toc" ) {
	print "$addon addon not exists.\n";
	next;
    }

    my $version;
    $version = read_interface_version("$addon/$addon.toc");
    if ( defined($version) && $version >= "70000" ) {
	$zip->addTree($addon, $addon);
	print "$addon addon added.\n";
    }
    else {
	print "$addon is legacy.\n";
    }
}
$zip->writeToFileNamed(APPLETREE_CURRENT);

move(APPLETREE_CURRENT, DROPBOX_PUBLIC);

exit;

sub read_addon_list {
    my $filename = shift or return;
    my @addons;
    my $fh;

    open($fh, '<', $filename) or return;
    while ( <$fh> ) {
	chomp;
	if ( /^[^#]/ ) {
	    push @addons, $_;
	}
    }
    close $fh;

    return @addons;
}

sub read_all_addon_list {
    my $dh;
    opendir $dh, '.';
    my @dirnames = grep {/^[^\.]/ && !/^Blizzard_/ && -d} readdir $dh;
    closedir $dh;

    return @dirnames;
}

sub read_interface_version {
    my $filename = shift or return;
    my $version = undef;

    my $fh;
    open($fh, '<', $filename) or return;
    while ( <$fh> ) {
	chomp;
	if ( /## Interface:\s+(\d+)/ ) {
	    $version = $1;
	    last;
	}
    }
    close $fh;

    return $version;
}
