use strict;


#
# This is a patch of a function in Palm::Doc to be able to handle
# DRM:ed files.
#


package Palm::Doc;

sub _parse_headerrec($) {
	my $record = shift;
	return undef unless exists $record->{'data'};

	# Doc header is minimum of 16 bytes
	return undef if length $record->{'data'} < 16;


	my ($version,$spare,$ulen, $records, $recsize, $position)
		= unpack( 'n n N n n N', $record->{'data'} );

	# the header is followed by a list of record sizes. We don't use
	# this since we can guess the sizes pretty easily by looking at
	# the actual records.

	# According to the spec, $version is either 1 (uncompressed)
	# or 2 (compress), while spare is always zero. AportisDoc supposedly sets
	# spare to something else, so screw AportisDoc.

    #
    # $version is 17480 for DRM:ed MobiPocket books
    #
    # So comment away the check
   ###	return undef if $version != DOC_UNCOMPRESSED and $version != DOC_COMPRESSED;

	return undef if $spare != 0;

	$record->{'version'} = $version;
	$record->{'length'} = $ulen;
	$record->{'records'} = $records;
	$record->{'recsize'} = $recsize;
	$record->{'position'} = $position;

	return $record;
}




package MobiPerl::MobiHeader;

use FindBin qw($RealBin);
use lib "$RealBin";

use MobiPerl::EXTH;

use strict;

#
# TYPE: 2=book
#
# VERSION: Should be 3 or 4
#
# CODEPAGE: utf-8: 65001; westerner: 1252
#
# IMAGERECORDINDEX: the index of the first record with image in it
#
# Language seems to be stored in 4E: en-us    0409
#                                       sv    041d
#                                       fi    000b
#                                       en    0009
#
# 0x50 and 0x54 might also be some kind of language specification
#

#
# 0000: MOBI        header-size type      codepage 
# 0010: unique-id   version     FFFFFFFF  FFFFFFFF
#
# header-size = E4 if version = 4
# type        = 2 - book
# codepage    = 1252 - westerner
# unique-id   = seems to be random
# version     = 3 or 4
#
# 0040: data4  exttitleoffset exttitlelength language
# 0050: data1  data2          data3          nonbookrecordpointer
# 0060: data5
#
# data1 and data2 id 09 in Oxford dictionary. The same as languange...
# nonbookrecordpointer in Oxford is 0x7167. data5 is 0x7157
# data3 is 05 in Oxford so maybe this is the version?
#


my %langmap = ("en-us" => 0x0409,
	       "sv"    => 0x041d,
	       "fi"    => 0x000b,
	       "en"    => 0x0009,
	       "en-gb" => 0x0809);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    bless {
	TYPE => 2,
	VERSION => 4,
	CODEPAGE => 1252,
	TITLE => "Unspecified Title",
	AUTHOR => "Unspecified Author",
	PUBLISHER => "",
	IMAGERECORDINDEX => 0,
	LANGUAGE => "en",
	COVEROFFSET => -1,
	THUMBOFFSET => -1,
	@_
    }, $class;
}

sub set_author {
    my $self = shift;
    my $val = shift;
    $self->{AUTHOR} = $val;
}

sub get_author {
    my $self = shift;
    return $self->{AUTHOR};
}

sub set_cover_offset {
    my $self = shift;
    my $val = shift;
    $self->{COVEROFFSET} = $val;
}

sub get_cover_offset {
    my $self = shift;
    return $self->{COVEROFFSET};
}

sub set_thumb_offset {
    my $self = shift;
    my $val = shift;
    $self->{THUMBOFFSET} = $val;
}

sub get_thumb_offset {
    my $self = shift;
    return $self->{THUMBOFFSET};
}

sub set_publisher {
    my $self = shift;
    my $val = shift;
    $self->{PUBLISHER} = $val;
}

sub get_publisher {
    my $self = shift;
    return $self->{PUBLISHER};
}

sub set_language {
    my $self = shift;
    my $val = shift;
    $self->{LANGUAGE} = $val;
}

sub get_language {
    my $self = shift;
    return $self->{LANGUAGE};
}

sub set_title {
    my $self = shift;
    my $val = shift;
    $self->{TITLE} = $val;
}

sub get_title {
    my $self = shift;
    return $self->{TITLE};
}

sub set_image_record_index {
    my $self = shift;
    my $val = shift;
    $self->{IMAGERECORDINDEX} = $val;
}

sub get_image_record_index {
    my $self = shift;
    return $self->{IMAGERECORDINDEX};
}

sub get_type {
    my $self = shift;
    return $self->{TYPE};
}

sub get_codepage {
    my $self = shift;
    return $self->{CODEPAGE};
}

sub set_version {
    my $self = shift;
    my $val = shift;
    $self->{VERSION} = $val;
}

sub get_version {
    my $self = shift;
    return $self->{VERSION};
}

sub get_unique_id {
    my $self = shift;
    my $r1 = int (rand (256));
    my $r2 = int (rand (256));
    my $r3 = int (rand (256));
    my $r4 = int (rand (256));
    my $res = $r1+$r2*256+$r3*256*256+$r4*256*256*256;
    return $res;
}

sub get_header_size {
    my $self = shift;
    my $res = 0x74;
    if ($self->get_version () == 4) {
	$res = 0xE4;
    }
    return $res;
}

sub get_extended_header_data {
    my $self = shift;
    my $author = $self->get_author ();

    my $eh = new MobiPerl::EXTH;
    $eh->set ("author", $author);
    my $pub = $self->get_publisher ();
    $eh->set ("pubisher", $pub) if $pub;

    my $coffset = $self->get_cover_offset ();
    if ($coffset >= 0) {
	$eh->set ("coveroffset", pack ("N", $coffset));
    }

    my $toffset = $self->get_thumb_offset ();
    if ($toffset >= 0) {
	$eh->set ("thumboffset", pack ("N", $toffset));
    }

#    $eh->set ("hasfakecover", pack ("N", 0));

    return $eh->get_data ();
}

sub get_data {
    my $self = shift;
    my $res = "";

    my $vie1 = 0; # 0x11 Alice 0x0D Rosenbaum 0xFFFFFFFF, Around the world
    $vie1 = 0xFFFFFFFF;

    my $vie2 = 0x04; # had this, around the world have 0x01

    my $use_extended_header = 1;
    my $extended_header_flag = 0x00;
    if ($use_extended_header) {
	$extended_header_flag = 0x50; # At MOBI+0x70
    }

    my $extended_title_offset = $self->get_header_size () + 16 + length ($self->get_extended_header_data ());
    my $extended_title_length = length ($self->get_title ());

    print STDERR "MOBIHDR: imgrecpointer: ", $self->get_image_record_index (), "\n";

    $res .= pack ("a*NNNNN", "MOBI",
		  $self->get_header_size (), 
		  $self->get_type (), 
		  $self->get_codepage (), 
		  $self->get_unique_id (), 
		  $self->get_version ());

    $res .= pack ("NN", 0xFFFFFFFF, 0xFFFFFFFF);
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
    $res .= pack ("NNNN", $vie1, $extended_title_offset, 
		  $extended_title_length, $langmap{$self->get_language ()});
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, $vie2, $self->get_image_record_index ());
    $res .= pack ("NNNN", 0xFFFFFFFF, 0, 0xFFFFFFFF, 0);
    $res .= pack ("N", $extended_header_flag);
#    print STDERR "MOBIHEADERSIZE: $mobiheadersize " . length ($header->{'data'}). "\n";
    while (length ($res) < $self->get_header_size ()) {
###	print STDERR "LEN: " . length ($res) . " - " . $self->get_header_size () . "\n";
	$res .= pack ("N", 0);
    }

    substr ($res, 0x94, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0x98, 4, pack ("N", 0xFFFFFFFF));

    substr ($res, 0xb0, 4, pack ("N", 0xFFFFFFFF)); 
    # maybe pointer to last image or to thumbnail image record

    substr ($res, 0xb8, 4, pack ("N", 0xFFFFFFFF)); # record pointer
    substr ($res, 0xc0, 4, pack ("N", 0xFFFFFFFF)); # record pointer
    substr ($res, 0xc8, 4, pack ("N", 0xFFFFFFFF)); # record pointer

    #
    # unknown
    #

    substr ($res, 0xd0, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0xd8, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0xdc, 4, pack ("N", 0xFFFFFFFF));


    $res .= $self->get_extended_header_data ();
    $res .= pack ("a*", $self->get_title ());
    
    #
    # Why?
    #
    for (1..48) {
	$res .= pack ("N", 0);
    }
    return $res;
}


#
# Help function that is not dependent on object state
#

sub get_extended_title {
    my $h = shift;
    my $len = length ($h);
    my ($exttitleoffset) = unpack ("N", substr ($h, 0x44));
    my ($exttitlelength) = unpack ("N", substr ($h, 0x48));
    my ($title) = unpack ("a$exttitlelength", substr ($h, $exttitleoffset-16));
    return $title;
}

sub set_extended_title {
    my $mh = shift;
    my $len = length ($mh);
    my $title = shift;
    my $titlelen = length ($title);
    my ($exttitleoffset) = unpack ("N", substr ($mh, 0x44));
    my ($exttitlelength) = unpack ("N", substr ($mh, 0x48));
    my ($version) = unpack ("N", substr ($mh, 0x14));

    my $res = substr ($mh, 0, $exttitleoffset-16);
    my $aftertitle = substr ($mh, $exttitleoffset-16+$exttitlelength);

    $res .= $title;

    my $diff = $titlelen - $exttitlelength;
    if ($diff <= 0) {
	foreach ($diff .. -1) {
	    $res .= pack ("C", 0);
	    $diff++;
	}
    } else {
	my $comp = $diff % 4;
	if ($comp) {
	    foreach ($comp .. 3) {
		$res .= pack ("C", 0);
		$diff++;
	    }
	}
    }
    $res = fix_pointers ($res, $exttitleoffset, $diff);

    $res .= $aftertitle;
    substr ($res, 0x48, 4, pack ("N", $titlelen));

    return $res;
}


sub set_exth_data {
    my $h = shift;
    my $len = length ($h);
    my $type = shift;
    my $data = shift;
    my $res = $h;
    print STDERR "Setting extended header data: $type - $data\n";

    my ($doctype, $length, $htype, $codepage, $uniqueid, $ver) =
	unpack ("a4NNNNN", $h);

    my ($exthflg) = unpack ("N", substr ($h, 0x70));
    if ($exthflg & 0x40) {
	my $exth = substr ($h, $length);
	my ($doctype, $exthlen, $n_items) = unpack ("a4NN", $exth);
	my $prefix = substr ($h, 0, $length);
	my $suffix = substr ($exth, $exthlen);

	my $eh = new MobiPerl::EXTH ($exth);
	$eh->set ($type, $data);
	print STDERR "GETSTRING: ", $eh->get_string ();

	#
	# Fix DRM and TITLE info pointers...
	#

	my $exthdata = $eh->get_data ();

	my $diff = length ($exthdata)-$exthlen;
	if ($diff <= 0) {
	    foreach ($diff .. -1) {
		$exthdata .= pack ("C", 0);
		$diff++;
	    }
	}

	$res = $prefix . $exthdata . $suffix;

	$res = fix_pointers ($res, $length, $diff);

    } else {
	print STDERR "EXTH does not exist, data not set: $type - $data\n";
    }
    return $res;
}


sub fix_pointers {
    my $mh = shift;
    my $startblock = shift;
    my $diff = shift;

    #
    # Fix pointers to long title and to DRM record
    # 

    my ($exttitleoffset) = unpack ("N", substr ($mh, 0x44));
    if ($exttitleoffset > $startblock and $diff > 0) {
	substr ($mh, 0x44, 4, pack ("N", $exttitleoffset+$diff));	
    }
    my ($drmoffset) = unpack ("N", substr ($mh, 0x98));
    if ($drmoffset != 0xFFFFFFFF and
	$drmoffset > $startblock and $diff > 0) {
	substr ($mh, 0x98, 4, pack ("N", $drmoffset+$diff));
    }
    return $mh;
}


return 1;
