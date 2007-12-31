package MobiPerl::Util;

use strict;

use GD;
use Image::BMP;

use HTML::TreeBuilder;

my $rescale_large_images = 1;


sub is_cover_image {
    my $file = shift;
    my $res = 0;
    if (not -e $file) {
	die "ERROR: File does not exist: $file";
    }
    my $p = new GD::Image ($file);
    if (not defined $p) {
	print STDERR "Could not read image file: $file\n";
    }
    my ($x, $y) = $p->getBounds();
#    my $x = $p->width;
#    my $y = $p->height;
    if ($x == 510 and $y == 680) {
	print STDERR "GUESSING COVERIMAGE: $file\n";
	$res = 1;
    }
    if ($x == 600 and $y == 800) {
	print STDERR "GUESSING COVERIMAGE: $file\n";
	$res = 1;
    }
    return $res;
}

#
# OPF related functions
#

sub get_tree_from_opf {
    my $file = shift;
    my $config = shift;
    my $linksinfo = shift;

    my $opf = new MobiPerl::Opf ($file);
    my $tochref = $opf->get_toc_href ();
    my @opf_spine_ids = $opf->get_spine_ids ();
    my @opf_manifest_ids = $opf->get_manifest_ids ();
    my $title = $opf->get_title ();
    print STDERR "OPFTITLE: $title\n";
    if ($config->title ()) {
	$title = $config->title ();
    }
    $title = $title = $config->prefix_title () . $title;
    $config->title ($title);

    my $author = $opf->get_author ();
    print STDERR "OPFAUTHOR: $author\n";
    if (not $config->author ()) {
	$config->author ($author);
    }



    #
    # If cover image not assigned search all files in current dir
    # and see if some file is a coverimage
    #
    
    my $coverimage = $opf->get_cover_image ();
    if ($coverimage eq "") {
	opendir DIR, ".";
	my @files = readdir (DIR);
	foreach my $f (@files) {
	    if ($f =~ /\.jpg/ or 
		$f =~ /\.JPG/ or 
		$f =~ /\.gif/) {
#		print STDERR "Checking if file is coverimage: $f\n";
		if (MobiPerl::Util::is_cover_image ($f)) {
		    $coverimage = $f;
		}
	    }
	}
    }

    my $html = HTML::Element->new('html');
    my $head = HTML::Element->new('head');

    #
    # Generate guide tag, specific for Mobipocket and is
    # not understood by HTML::TreeBuilder...
    #

    
    my $guide = HTML::Element->new('guide');
    if ($tochref) {
	my $tocref = HTML::Element->new('reference', 
					title=>"Table of Contents",
					type=>"toc",
					href=>"\#$tochref");
	$guide->push_content ($tocref);
    }

    if ($config->add_cover_link ()) {
	my $coverref = HTML::Element->new('reference', 
					  title=>"Cover",
					  type=>"cover",
					  href=>"\#addedcoverlink");
	$guide->push_content ($coverref);
    }
    $head->push_content ($guide);

    my $titleel = HTML::Element->new('title');
    $titleel->push_content ($title);
    $head->push_content ($titleel);

    #
    # Generate body
    #

    my $body = HTML::Element->new('body');

#				  topmargin => "0",
#				  leftmargin => "0",
#				  bottommargin => "0",
#				  rightmargin => "0");


    my $coverp = HTML::Element->new('p', 
				    id=>"addedcoverlink",
				    align=>"center");
    my $coverimageel = HTML::Element->new('a', 
					  onclick => 
					  "document.goto_page_relative(1)");
    $coverp->push_content ($coverimageel);

    if ($config->add_cover_link ()) {
	$body->push_content ($coverp);
	$body->push_content (HTML::Element->new('mbp:pagebreak'));
    }

#<p align="center"><a onclick="document.goto_page_relative(1)"><img src="pda_cover.gif" hisrc="pc_cover.gif" /></a></p>

    #
    # Add TOC first also if --tocfirst
    #
    if ($tochref and $config->toc_first ()) {
	print STDERR "ADDING TOC FIRST ALSO: $tochref\n";
	my $tree = new HTML::TreeBuilder ();
	$tree->ignore_unknown (0);
	$tree->parse_file ($tochref) || die "Could not find file: $tochref\n";
###	check_for_links ($tree);
	$linksinfo->check_for_links ($tree);
	my $b = $tree->find ("body");
	$body->push_content ($b->content_list());
	$body->push_content (HTML::Element->new('mbp:pagebreak'));
    }


    #
    # All files in manifest
    #

    foreach my $id (@opf_spine_ids) {
	my $filename = $opf->get_href ($id);
	my $mediatype = $opf->get_media_type ($id);

##	print STDERR "SPINE: adding $id - $filename - $mediatype\n";

	next unless ($mediatype =~ /text/); # only include text content

	my $tree = new HTML::TreeBuilder ();
	$tree->ignore_unknown (0);
	$tree->parse_file ($filename) || die "Could not find file: $filename\n";

###	check_for_links ($tree);
	$linksinfo->check_for_links ($tree);

	print STDERR "Adding: $filename - $id\n";

#	my $tree = $file_to_tree{$file};
#	my $title = $file_to_title{$file};
#	my $nameref = $file_to_nameref{$file};
#	my $h2 = HTML::Element->new('h2');
#	my $a = HTML::Element->new('a', name => "$nameref");
#	$a->push_content ("$title");
#	$h2->push_content ($a);
#	$body->push_content ($h2);

##	print STDERR "FILETOLINKCHECK:$filename:\n";
	if ($linksinfo->link_exists ($filename)) {
##	    print STDERR "FILETOLINKCHECK:$filename: SUCCESS\n";
	    my $a = HTML::Element->new('a', name => $filename);
	    $body->push_content ($a);
	}

	my $b = $tree->find ("body");
	$body->push_content ($b->content_list());
    }

    #
    # Check if no images in document and include cover image if it exists
    #

    if ($config->cover_image ()) {
	$coverimage = $config->cover_image ();
    }

    if ($linksinfo->get_n_images () == 0) {
	if ($coverimage) {
	    print STDERR "NO IMAGES IN BOOK: Adding cover image: $coverimage\n";
	    $linksinfo->add_image_link ($coverimage);
####	    $record_index++;
####	    $record_to_image_file{$record_index} = $coverimage;
	    if ($config->add_cover_link ()) {
		my $el = HTML::Element->new ('img', recindex => "00001");
		$coverimageel->push_content ($el);
	    }
	}
    }

    #
    #  Fix anchor to positions given by id="III"...
    #
    # filepos="0000057579"
    #

    my @refs = $body->look_down ("href", qr/^\#/);
    push @refs, $head->look_down ("href", qr/^\#/);
    my @hrefs = ();
    my @refels = ();
    my %href_to_ref = ();
    foreach my $r (@refs) {
	$r->attr ("filepos", "0000000000");
	my $key = $r->attr ("href");
	$key =~ s/\#//g;
	push @hrefs, $key;
	push @refels, $r;
#	$r->attr ("href", undef);
    }

    $html->push_content ($head);
    $html->push_content ($body);
    my $data = $html->as_HTML ();
    foreach my $i (0..$#hrefs) {
	my $h = $hrefs[$i];
	my $r = $refels[$i];
	my $searchfor1 = "id=\"$h\"";
	my $searchfor2 = "<a name=\"$h\"";
	
###	print STDERR "SEARCHFOR1: $searchfor1\n";
	my $pos = index ($data, $searchfor1);
	if ($pos >= 0) {
	    #
	    # search backwards for <
	    #
	    
	    while (substr ($data, $pos, 1) ne "<") {
		$pos--;
	    }

##	    $pos -=4; # back 4 positions to get to <h2 id=
	    my $form = "0" x (10-length($pos)) . "$pos";
	    print STDERR "POSITION: $pos - $searchfor1 - $form\n";
	    $r->attr ("filepos", "$form");
	} else {
###	    print STDERR "SEARCHFOR2: $searchfor2\n";
	    $pos = index ($data, $searchfor2);
	    if ($pos >= 0) {
		my $form = "0" x (10-length($pos)) . "$pos";
###		print STDERR "POSITION: $pos - $searchfor2 - $form\n";
		$r->attr ("filepos", "$form");
	    } else {
	    }
	}
    }
    

#    my @anchors = $body->look_down ("id", qr/./);
#    foreach my $a (@anchors) {
#	my $name = $a->attr("id");
#	my $tag = $a->tag ();
#	my $text = $a->as_trimmed_text ();
#	if ($link_exists{$name}) {
#	    $a->delete_content ();
#	    my $ael = HTML::Element->new('a', name => $name);
#	    $ael->push_content ($text);
#	    $a->push_content ($ael);
#	}
#	print STDERR "ANCHORS: $tag - $name - $text\n";
#    }



#    $html->push_content ($head);
#    $html->push_content ($body);
    return $html;
}


#
# lit file functons
#

sub unpack_lit_file {
    my $litfile = shift;
    my $unpackdir = shift;

    print STDERR "Unpack file $litfile in dir $unpackdir\n";

    mkdir $unpackdir;

    opendir DIR, $unpackdir;
    my @files = readdir (DIR);
    foreach my $f (@files) {
	if ($f =~ /^\./) {
	    next;
	}
	if ($f =~ /^\.\./) {
	    next;
	}
#    print STDERR "FILE: $f\n";
	unlink "$unpackdir/$f";
    }

    system ("clit \"$litfile\" $unpackdir") == 0
	or die "system (clit $litfile $unpackdir) failed: $?";

}

sub get_thumb_cover_image_data {
    my $filename = shift;
##    print STDERR "COVERIMAGE: $filename\n";
    my $data = "";

    if (not -e $filename) {
	print STDERR "Image file does not exist: $filename\n";
	return $data;
    }

    my $p = new GD::Image ("$filename");
    my ($x, $y) = $p->getBounds();
#    my $x = $p->width;
#    my $y = $p->height;
##    add_text_to_image ($p, $opt_covertext);
    my $scaled = scale_gd_image ($p, 180, 240);
    print STDERR "Resizing image $x x $y -> 180 x 240 -> scaled.jpg\n";
    return $scaled->jpeg ();
}

sub scale_gd_image {
    my $im = shift;
    my $x = shift;
    my $y = shift;
    my ($w0, $h0) = $im->getBounds();
#    my $w0 = $im->width;
#    my $h0 = $im->height;
    my $w1 = $w0*$x;
    my $h1 = $h0*$x;
##    print STDERR "SCALE GD: $w0 $h0 $w1 $h1\n";
    if (defined $y) {
	$w1 = $x;
	$h1 = $y;
    }
    my $res = new GD::Image ($w1, $h1);
    $res->copyResized ($im, 0, 0, 0, 0, $w1, $h1, $w0, $h0);
    return $res;
}


sub get_text_image {
    my $width = shift;
    my $height = shift;
    my $text = shift;
#    my $image = Image::Magick->new;
#    $image->Set(size=>"$width x $height");
#    $image->ReadImage('xc:white');
#    $image->Draw (pen => "red",
#		  primitive => "text",
#		  x => 200,
#		  y => 200,
#		  font => "Bookman-DemiItalic",
#		  text => "QQQQ$text, 200, 200",
#		  fill => "black",
#		  pointsize => 40);
#    $image->Draw(pen => 'red', fill => 'red', primitive => 'rectangle',
#		 points => '20,20 100,100');
#    $image->Write (filename => "draw2.jpg");
}

sub get_gd_image_data {
    my $im = shift;
    my $filename = shift;
    my $quality = shift;

    $quality = -1 if not defined $quality;

    #
    # For some strange reason it does not work if using
    # the gif file with size 600x800
    #

##    if ($filename =~ /\.gif/ or $filename =~ /\.GIF/) {
##	return $im->gif ();
##    }

    if ($quality <= 0) {
	return $im->jpeg ();
    } else {
	return $im->jpeg ($quality);
    }
}

sub add_text_to_image {
    my $im = shift;
    my $text = shift;
    my $x = $im->Get ("width");
    my $y = $im->Get ("height");

    if (defined $text and $text) {
	print STDERR "DRAW TEXT: $text\n";
	my $textim = get_text_image ($x, $y, $text);
	$im->Draw (primitive => "text",
		   text => $text,
		   points => "50,50",
		   fill => "red",
		   pointsize => 72);
    }
    $im->Write (filename => "draw.jpg");

}

sub get_image_data {
    my $filename = shift;
    my $rescale = shift;

    $rescale_large_images = $rescale if defined $rescale;

    my $data = "";

    if (not -e $filename) {
	print STDERR "Image file does not exist: $filename\n";
	return $data;
    }

    print STDERR "Reading data from file: $filename\n";

    my $p = new GD::Image ("$filename");
    if (not defined $p) {
	my $im = new Image::BMP (file => "$filename");
	if (defined $im) {
	    my $w = $im->{Width};
	    my $h = $im->{Height};
	    print STDERR "BMP IMAGE $filename: $w x $h\n";
	    $p = new GD::Image ($w, $h);
	    foreach my $x (0..$w-1) {
		foreach my $y (0..$h-1) {
		    my ($r,$g,$b) = $im->xy_rgb ($x, $y);
		    my $index = $p->colorExact ($r, $g, $b);
		    if ($index == -1) {
			$index = $p->colorAllocate ($r, $g, $b);
		    }
		    $p->setPixel ($x, $y, $index);
		}
	    }
	}
##	open IMAGE, ">dummy-$filename.jpg";
##	print IMAGE $p->jpeg ();
##	close IMAGE;
    }
    my ($x, $y) = $p->getBounds();
#    my $x = $p->width;
#    my $y = $p->height;

    #
    # If I do not resize 600x800 images it does not work on Gen3
    #
    # check this one more time, 600x800 gif and jpeg with size
    # less than 64K does not work on Gen3
    #

    if ($rescale_large_images) {
	if ($x > 480) {
	    # width might be the problem...
	    my $scale = 480.0/$x; # 0.99 does not work, 480x640 works
	    $p = MobiPerl::Util::scale_gd_image ($p, $scale);
##	    $p = MobiPerl::Util::scale_gd_image ($p, 600, 810);
	}
    }

    #
    #   Scale if scale option given
    #   or does it work just setting width?
    #

  ##  $filename =~ s/\....$/\.gif/;
  ##  print STDERR "UTIL FILENAME: $filename\n";

    my $quality = -1;
    my $size = length (MobiPerl::Util::get_gd_image_data ($p, $filename));
    my $maxsize = 60000;

##    $maxsize = 35000;


    if ($size > $maxsize) {
	$quality = 100;
	while (length (MobiPerl::Util::get_gd_image_data ($p, $filename, $quality)) >
	       $maxsize and $quality >= 0) {
	    $quality -= 10;
	}
	if ($quality < 0) {
	    die "Could not shrink image file size for $filename";
	}
    } 

##    if ($y < 640 and $x < 480 and defined $opt_scale) {
##	my $scale = $opt_scale;
##	$p = MobiPerl::Util::scale_gd_image ($p, $scale);
##	print STDERR "Rescaling $$scale\n";
##    }


    my $data = MobiPerl::Util::get_gd_image_data ($p, $filename, $quality);
    return $data;
}

sub iso2hex($) {
    my $hex = '';
    for (my $i = 0; $i < length($_[0]); $i++) {
	my $ordno = ord substr($_[0], $i, 1);
	$hex .= sprintf("%lx", $ordno);
    }

    $hex =~ s/ $//;;
    $hex;
}


return 1;
