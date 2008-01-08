package MobiPerl::EXTH;

use FindBin qw($RealBin);
use lib "$RealBin";

use strict;

# 400-499 application binary
# 500-599 application string

my %typename_to_type = ("drm_server_id" => 1,
			"drm_commerce_id" => 2,
			"drm_ebookbase_book_id" => 3,
			"author" => 100,
			"publisher" => 101,
			"imprint" => 102,
			"abstract" => 103,
			"isbn" => 104,
			"subject" => 105,
			"publishingdate" => 106,
			"subjectcode" => 110,
			"asin" => 113,
			"versionnumber" => 114,
			"sample" => 115,
			"coveroffset" => 201,
			"thumboffset" => 202,
			"hasfakecover" => 203,
			"204"          => 204,
			"205"          => 205,
			"206"          => 206,
			"207"          => 207,
			"clippinglimit" => 401,  # varies in size 1 or 4 seend
			"publisherlimit" => 402,
			"403"          => 403,
			"cdetype"      => 501,
			"lastupdatetime" => 502,
			"updatedtitle"   => 503,
			);

my %type_to_desc = (1 => "drm_server_id",
		    2 => "drm_commerce_id",
		    3 => "drm_ebookbase_book_id",
		    100 => "Author",
		    101 => "Publisher",
		    102 => "Imprint",
		    103 => "Abstact",
		    104 => "ISBN",
		    105 => "Subject",
		    106 => "PublishingDate",
		    107 => "Review",
		    108 => "Contributor",
		    109 => "Rights",
		    110 => "SubjectCode",
		    111 => "Type",
		    112 => "Source",
		    113 => "ASIN",
		    114 => "VersionNumber",
		    115 => "Sample",
		    116 => "StartReading",
		    201 => "CoverOffset",
		    202 => "ThumbOffset",
		    203 => "hasFakeCover",
		    401 => "ClippingLimit",
		    402 => "PublisherLimit",
		    501 => "CDEContentType",
		    502 => "LastUpdateTime",
		    503 => "UpdatedTitle",
		    504 => "cDEContentKey",
		    );

my %binary_data = (114 => 1,
		   115 => 1,
		   201 => 1,
		   202 => 1,
		   203 => 1,
		   204 => 1,
		   205 => 1,
		   206 => 1,
		   207 => 1,
		   300 => 1,
		   401 => 1,
		   403 => 1,
		   );

my %format = (114 => 4,
	      201 => 4,
	      202 => 4,
	      203 => 4,
	      204 => 4,
	      205 => 4,
	      206 => 4,
	      207 => 4,
	      403 => 1);




sub new {
    my $this = shift;
    my $data = shift;
    my $class = ref($this) || $this;
    my $obj = bless {
	TYPE => [],
	DATA => [],
	@_
    }, $class;
    $obj->initialize_from_data ($data) if defined $data;
    return $obj;
}

sub get_string {
    my $self = shift;
    my @type = @{$self->{TYPE}};
    my @data = @{$self->{DATA}};
    my $res = "";
    foreach my $i (0..$#type) {
	my $type = $type[$i];
	my $data = $data[$i];
	my $typedesc = $type;
	if (defined $type_to_desc{$type}) {
	    $typedesc = $type_to_desc{$type};
	    if (defined $binary_data{$type}) {
		$res .= $typedesc . " - " . "not printable" . "\n";
	    } else {
		$res .= $typedesc . " - " . $data . "\n";
	    }
	}
    }
    return $res;
}

sub add {
    my $self = shift;
    my $typename = shift;
    my $data = shift;
    my $type = $self->get_type ($typename);
    if (is_binary_data ($type)) {
	my $hex = MobiPerl::Util::iso2hex ($data);
	print STDERR "EXTH add: $typename - $type - ", int($data), " - $hex\n";
    } else {
	print STDERR "EXTH add: $typename - $type - $data\n";
    }
    if ($type) {
	push @{$self->{TYPE}}, $type;
	push @{$self->{DATA}}, $data;
    }
    return $type;
}

sub get_type {
    my $self = shift;
    my $typename = shift;
    my $res = 0;
###    print STDERR "EXTH: GETTYPE: $typename\n";
    if (defined $typename_to_type{$typename}) {
	$res = $typename_to_type{$typename};
    }
    return $res;
}

sub set {
    my $self = shift;
    my $typename = shift;
    my $data = shift;
    my $type = $self->get_type ($typename);
    my $hex = MobiPerl::Util::iso2hex ($data);
    print STDERR "EXTH setting data: $typename - $type - $data - $hex\n";
    if ($type) {
	my @type = @{$self->{TYPE}};
	my @data = @{$self->{DATA}};
	my $found = 0;
	foreach my $i (0..$#type) {
	    if ($type[$i] == $type) {
		print STDERR "EXTH replacing data: $type - $data - $hex\n";
		$self->{TYPE}->[$i] = $type;
		$self->{DATA}->[$i] = $data;
		$found = 1;
		last;
	    }
	}
	if (not $found) {
	    $self->add ($typename, $data);
	}
    }
    return $type;
}

sub initialize_from_data {
    my $self = shift;
    my $data = shift;
    my ($doctype, $len, $n_items) = unpack ("a4NN", $data);
##    print "EXTH doctype: $doctype\n";
##    print "EXTH  length: $len\n";
##    print "EXTH n_items: $n_items\n";
    my $pos = 12;
    foreach (1..$n_items) {
	my ($id, $size) = unpack ("NN", substr ($data, $pos));
	my $contlen = $size-8;
	my ($type, $size, $content) = unpack ("NNa$contlen", substr ($data, $pos));
	if (defined $format{$type}) {
	    my $len = $format{$type};
	    print STDERR "TYPE:$type:$len\n";
	    if ($len == 4) {
		($type, $size, $content) = unpack ("NNN", substr ($data, $pos));
		print STDERR "CONT:$content\n";
	    }
	    if ($len == 1) {
		($type, $size, $content) = unpack ("NNC", substr ($data, $pos));
		print STDERR "CONT:$content\n";
	    }
	}
	push @{$self->{TYPE}}, $type;
	push @{$self->{DATA}}, $content;
	$pos += $size;
    }
    if ($self->get_data () ne substr ($data, 0, $len)) {
	print STDERR "ERROR: generated EXTH does not match original\n";
	my $s1 = $self->get_data ();
	my $s0 = substr ($data, 0, $len);
	foreach my $i (0..length ($s0)-1) {
	    if (substr ($s0, $i, 1) ne substr ($s1, $i, 1)) {
		my $c0 = substr ($s0, $i, 1);
		my $c1 = substr ($s1, $i, 1);
		$c0 = MobiPerl::Util::iso2hex ($c0);
		$c1 = MobiPerl::Util::iso2hex ($c1);
		print STDERR "MISMATCH POS:$i:$c0:$c1\n";
	    }
	}
    }
    open EXTH0, ">exth0";
    print EXTH0 substr ($data, 0, $len);
    open EXTH1, ">exth1";
    print EXTH1 $self->get_data ();
}

sub get_data {
    my $self = shift;
    my @type = @{$self->{TYPE}};
    my @data = @{$self->{DATA}};
    my $exth = pack ("a*", "EXTH");
    my $content = "";
    my $n_items = 0;
    foreach my $i (0..$#type) {
	my $type = $type[$i];
	my $data = $data[$i];
	next unless defined $data; # remove type...
	if (defined $format{$type}) {
	    my $len = $format{$type};
	    if ($len == 4) {
		$content .= pack ("NNN", $type, $len+8, $data);
	    }
	    if ($len == 1) {
		$content .= pack ("NNC", $type, $len+8, $data);
	    }
	} else {
	    $content .= pack ("NNa*", $type, length ($data)+8, $data);
	}
	$n_items++;
    }
    #
    # Maybe fill up to even 4...
    #

    my $comp = length ($content) % 4;
    if ($comp) {
	foreach ($comp .. 3) {
	    $content .= pack ("C", 0);
	}
    }
    $exth .= pack ("NN", length ($content)+12, $n_items);
    $exth .= $content;
    return $exth;
}

sub get_cover_offset {
    my $self = shift;
    my $res = 0;
    my @type = @{$self->{TYPE}};
    my @data = @{$self->{DATA}};
    my $res = 0;
    foreach my $i (0..$#type) {
	if ($type[$i] == 201) {
	    ($res) = unpack ("N", $data[$i]);
	}
    }
    return $res;
}

#
# Non object methods
#

sub get_description {
    my $type = shift;
    my $res = $type;
    if (defined $type_to_desc{$type}) {
	$res = $type_to_desc{$type};
    }
    return $res;
}

sub is_binary_data {
    my $type = shift;
    return $binary_data{$type};
}

return 1;
