package MobiPerl::EXTH;

use FindBin qw($RealBin);
use lib "$RealBin";

use strict;

my %typename_to_type = ("author" => 100,
			"publisher" => 101,
			"imprint" => 102,
			"subject" => 105,
			"publishingdate" => 106,
			"coveroffset" => 201,
			"thumboffset" => 202,
			"hasfakecover" => 203,
			);

my %type_to_desc = (1 => "drm_server_id",
		   2 => "drm_commerce_id",
		   3 => "drm_ebookbase_book_id",
		   100 => "Author",
		   101 => "Publisher",
		   102 => "Imprint",
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
		   203 => "hasFakeCover");

my %binary_data = (300 => 1,
		   201 => 1,
		   202 => 1,
		   203 => 1,
		   300 => 1,);


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
	print STDERR "EXTH add: $typename - $type - ", int($data), "\n";
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
###    print STDERR "EXTH setting data: $type - $data\n";
    if ($type) {
	my @type = @{$self->{TYPE}};
	my @data = @{$self->{DATA}};
	my $found = 0;
	foreach my $i (0..$#type) {
	    if ($type[$i] == $type) {
		print STDERR "EXTH setting data: $data - $type\n";
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
	push @{$self->{TYPE}}, $type;
	push @{$self->{DATA}}, $content;
	$pos += $size;
    }
    if ($self->get_data () ne substr ($data, 0, $len)) {
	print STDERR "ERROR: generated EXTH does not match original\n";
    }
##    open EXTH0, ">exth0";
##    print EXTH0 substr ($data, 0, $len);
##    open EXTH1, ">exth1";
##    print EXTH1 $self->get_data ();
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
	$content .= pack ("NNa*", $type, length ($data)+8, $data);
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
