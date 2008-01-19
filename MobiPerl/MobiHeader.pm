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


my %mainlanguage = (
		 0 => "NEUTRAL",
		 54 => "AFRIKAANS",
		 28 => "ALBANIAN",
		 1 => "ARABIC",
		 43 => "ARMENIAN",
		 77 => "ASSAMESE",
		 44 => "AZERI",
		 45 => "BASQUE",
		 35 => "BELARUSIAN",
		 69 => "BENGALI",
		 2 => "BULGARIAN",
		 3 => "CATALAN",
		 4 => "CHINESE",
		 26 => "CROATIAN",
		 5 => "CZECH",
		 6 => "DANISH",
		 19 => "DUTCH",
		 9 => "ENGLISH",
		 37 => "ESTONIAN",
		 56 => "FAEROESE",
		 41 => "FARSI",
		 11 => "FINNISH",
		 12 => "FRENCH",
		 55 => "GEORGIAN",
		 7 => "GERMAN",
		 8 => "GREEK",
		 71 => "GUJARATI",
		 13 => "HEBREW",
		 57 => "HINDI",
		 14 => "HUNGARIAN",
		 15 => "ICELANDIC",
		 33 => "INDONESIAN",
		 16 => "ITALIAN",
		 17 => "JAPANESE",
		 75 => "KANNADA",
		 63 => "KAZAK",
		 87 => "KONKANI",
		 18 => "KOREAN",
		 38 => "LATVIAN",
		 39 => "LITHUANIAN",
		 47 => "MACEDONIAN",
		 62 => "MALAY",
		 76 => "MALAYALAM",
		 58 => "MALTESE",
		 78 => "MARATHI",
		 97 => "NEPALI",
		 20 => "NORWEGIAN",
		 72 => "ORIYA",
		 21 => "POLISH",
		 22 => "PORTUGUESE",
		 70 => "PUNJABI",
		 23 => "RHAETOROMANIC",
		 24 => "ROMANIAN",
		 25 => "RUSSIAN",
		 59 => "SAMI",
		 79 => "SANSKRIT",
		 26 => "SERBIAN",
		 27 => "SLOVAK",
		 36 => "SLOVENIAN",
		 46 => "SORBIAN",
		 10 => "SPANISH",
		 48 => "SUTU",
		 65 => "SWAHILI",
		 29 => "SWEDISH",
		 73 => "TAMIL",
		 68 => "TATAR",
		 74 => "TELUGU",
		 30 => "THAI",
		 49 => "TSONGA",
		 50 => "TSWANA",
		 31 => "TURKISH",
		 34 => "UKRAINIAN",
		 32 => "URDU",
		 67 => "UZBEK",
		 42 => "VIETNAMESE",
		 52 => "XHOSA",
		 53 => "ZULU",
		 );


my $langmap = {};
$langmap->{"ENGLISH"} = {
		   1 => "ENGLISH_US",
		   2 => "ENGLISH_UK",
		   3 => "ENGLISH_AUS",
		   4 => "ENGLISH_CAN",
		   5 => "ENGLISH_NZ",
		   6 => "ENGLISH_EIRE",
		   7 => "ENGLISH_SOUTH_AFRICA",
		   8 => "ENGLISH_JAMAICA",
		   10 => "ENGLISH_BELIZE",
		   11 => "ENGLISH_TRINIDAD",
		   12 => "ENGLISH_ZIMBABWE",
		   13 => "ENGLISH_PHILIPPINES",
	       };

my %sublanguage = (
		   0 => "NEUTRAL",
		   1 => "ARABIC_SAUDI_ARABIA",
		   2 => "ARABIC_IRAQ",
		   3 => "ARABIC_EGYPT",
		   4 => "ARABIC_LIBYA",
		   5 => "ARABIC_ALGERIA",
		   6 => "ARABIC_MOROCCO",
		   7 => "ARABIC_TUNISIA",
		   8 => "ARABIC_OMAN",
		   9 => "ARABIC_YEMEN",
		   10 => "ARABIC_SYRIA",
		   11 => "ARABIC_JORDAN",
		   12 => "ARABIC_LEBANON",
		   13 => "ARABIC_KUWAIT",
		   14 => "ARABIC_UAE",
		   15 => "ARABIC_BAHRAIN",
		   16 => "ARABIC_QATAR",
		   1 => "AZERI_LATIN",
		   2 => "AZERI_CYRILLIC",
		   1 => "CHINESE_TRADITIONAL",
		   2 => "CHINESE_SIMPLIFIED",
		   3 => "CHINESE_HONGKONG",
		   4 => "CHINESE_SINGAPORE",
		   1 => "DUTCH",
		   2 => "DUTCH_BELGIAN",
		   1 => "FRENCH",
		   2 => "FRENCH_BELGIAN",
		   3 => "FRENCH_CANADIAN",
		   4 => "FRENCH_SWISS",
		   5 => "FRENCH_LUXEMBOURG",
		   6 => "FRENCH_MONACO",
		   1 => "GERMAN",
		   2 => "GERMAN_SWISS",
		   3 => "GERMAN_AUSTRIAN",
		   4 => "GERMAN_LUXEMBOURG",
		   5 => "GERMAN_LIECHTENSTEIN",
		   1 => "ITALIAN",
		   2 => "ITALIAN_SWISS",
		   1 => "KOREAN",
		   1 => "LITHUANIAN",
		   1 => "MALAY_MALAYSIA",
		   2 => "MALAY_BRUNEI_DARUSSALAM",
		   1 => "NORWEGIAN_BOKMAL",
		   2 => "NORWEGIAN_NYNORSK",
		   2 => "PORTUGUESE",
		   1 => "PORTUGUESE_BRAZILIAN",
		   2 => "SERBIAN_LATIN",
		   3 => "SERBIAN_CYRILLIC",
		   1 => "SPANISH",
		   2 => "SPANISH_MEXICAN",
		   4 => "SPANISH_GUATEMALA",
		   5 => "SPANISH_COSTA_RICA",
		   6 => "SPANISH_PANAMA",
		   7 => "SPANISH_DOMINICAN_REPUBLIC",
		   8 => "SPANISH_VENEZUELA",
		   9 => "SPANISH_COLOMBIA",
		   10 => "SPANISH_PERU",
		   11 => "SPANISH_ARGENTINA",
		   12 => "SPANISH_ECUADOR",
		   13 => "SPANISH_CHILE",
		   14 => "SPANISH_URUGUAY",
		   15 => "SPANISH_PARAGUAY",
		   16 => "SPANISH_BOLIVIA",
		   17 => "SPANISH_EL_SALVADOR",
		   18 => "SPANISH_HONDURAS",
		   19 => "SPANISH_NICARAGUA",
		   20 => "SPANISH_PUERTO_RICO",
		   1 => "SWEDISH",
		   2 => "SWEDISH_FINLAND",
		   1 => "UZBEK_LATIN",
		   2 => "UZBEK_CYRILLIC",
		   );

my %booktypedesc = (2 => "BOOK",
		    3 => "PALMDOC",
		    4 => "AUDIO",
		    257 => "NEWS",
		    258 => "NEWS_FEED",
		    259 => "NEWS_MAGAZINE",
		    513 => "PICS",
		    514 => "WORD",
		    515 => "XLS",
		    516 => "PPT",
		    517 => "TEXT",
		    518 => "HTML",
		   );

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
##	my $data = pack ("N", $coffset);
##	print STDERR "COFFSET:$coffset:$data:\n";
	$eh->set ("coveroffset", $coffset);
    }

    my $toffset = $self->get_thumb_offset ();
    if ($toffset >= 0) {
##	my $data = pack ("N", $toffset);
##	my $hex = MobiPerl::Util::iso2hex ($data);
##	print STDERR "TOFFSET:$toffset:$hex\n";
	$eh->set ("thumboffset", $toffset);
    }

##    $eh->set ("hasfakecover", pack ("N", 0));

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

sub get_mh_language_code {
    my $h = shift;
    my $len = length ($h);
    my ($lang) = unpack ("N", substr ($h, 0x4C));
    return $lang;
}

sub get_language_desc {
    my $code = shift;
    my $lid = $code & 0xFF;
    my $lang = $mainlanguage{$lid};
    my $sublid = ($code >> 10) & 0xFF;
    my $sublang = $langmap->{$lang}->{$sublid};
    my $res = "";
    $res .= "$lang";
    $res .= " - $sublang";
    return $res;
}






sub set_booktype {
    my $mh = shift;
    my $len = length ($mh);
    my $type = shift;
    substr ($mh, 0x08, 4, pack ("N", $type));
    return $mh;
}


sub set_exth_data {
    my $h = shift;
    my $len = length ($h);
    my $type = shift;
    my $data = shift;
    my $res = $h;
    if (defined $data) {
	print STDERR "Setting extended header data: $type - $data\n";
    } else {
	print STDERR "Deleting extended header data of type: $type\n";
    }

    my ($doctype, $length, $htype, $codepage, $uniqueid, $ver) =
	unpack ("a4NNNNN", $h);

    my ($exthflg) = unpack ("N", substr ($h, 0x70));

    my $exth = substr ($h, $length);
    my $prefix = substr ($h, 0, $length);
    my $suffix;
    my $eh;
    my $exthlen = 0;
    if ($exthflg & 0x40) {
	my ($doctype, $exthlen1, $n_items) = unpack ("a4NN", $exth);
	$exthlen = $exthlen1;
	$suffix = substr ($exth, $exthlen);
	$eh = new MobiPerl::EXTH ($exth);
    } else {
	$eh = new MobiPerl::EXTH ();
	$suffix = $exth;
	substr ($prefix, 0x70, 4, pack ("N", $exthflg | 0x40));
    }
    
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

sub get_booktype_desc {
    my $type = shift;
    my $res = $type;
    if (defined $booktypedesc{$type}) {
	$res = $booktypedesc{$type};
    }
    return $res;
}



return 1;
