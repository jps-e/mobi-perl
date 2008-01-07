package MobiPerl::Config;

use FindBin qw($RealBin);
use lib "$RealBin";

use strict;

sub new {
    my $this = shift;
    my $data = shift;
    my $class = ref($this) || $this;
    my $obj = bless {
	ADDCOVERLINK => 0,
	TOCFIRST => 0,
	COVERIMAGE => "",
	THUMBIMAGE => "",
	AUTHOR => "",
	TITLE => "",
	PREFIXTITLE => "",
	NOIMAGES => 0,
	FIXHTMLBR => 0,
	@_
    }, $class;
    $obj->initialize_from_file ($data) if defined $data;
    return $obj;
}

sub add_cover_link {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{ADDCOVERLINK} = $val;
    } else {
	return $self->{ADDCOVERLINK};
    }
}

sub toc_first {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{TOCFIRST} = $val;
    } else {
	return $self->{TOCFIRST};
    }
}

sub cover_image {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{COVERIMAGE} = $val;
    } else {
	return $self->{COVERIMAGE};
    }
}

sub thumb_image {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{THUMBIMAGE} = $val;
    } else {
	return $self->{THUMBIMAGE};
    }
}

sub author {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{AUTHOR} = $val;
    } else {
	return $self->{AUTHOR};
    }
}

sub title {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{TITLE} = $val;
    } else {
	return $self->{TITLE};
    }
}

sub prefix_title {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{PREFIXTITLE} = $val;
    } else {
	return $self->{PREFIXTITLE};
    }
}

sub no_images {
    my $self = shift;
    my $val = shift;
    if (defined $val) {
	$self->{NOIMAGES} = $val;
    } else {
	return $self->{NOIMAGES};
    }
}

return 1;
