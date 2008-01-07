
FILEPREFIX = mobiperl-0.0.23
TARFILE =$(FILEPREFIX).tar
RARFILE =$(FILEPREFIX)-win.rar


PALMFILES = Palm/Doc.pm

MOBIPERLFILES = \
	MobiPerl/Config.pm \
	MobiPerl/EXTH.pm \
	MobiPerl/LinksInfo.pm \
	MobiPerl/MobiFile.pm \
	MobiPerl/MobiHeader.pm \
	MobiPerl/Opf.pm \
	MobiPerl/Util.pm \

FILES = mobi2html html2mobi lit2mobi \
        mobi2mobi opf2mobi \
	gpl-3.0.txt \
	Makefile README

dist:
	-rm -rf $(FILEPREFIX)
	-mkdir $(FILEPREFIX)
	-mkdir $(FILEPREFIX)/Palm
	-mkdir $(FILEPREFIX)/MobiPerl
	cp $(FILES) $(FILEPREFIX)/
	cp $(PALMFILES) $(FILEPREFIX)/Palm/
	cp $(MOBIPERLFILES) $(FILEPREFIX)/MobiPerl/
	tar cvf $(TARFILE) $(FILEPREFIX)/
	pod2html mobi2mobi > html/mobi2mobi.html
	pod2html mobi2html > html/mobi2html.html
	pod2html lit2mobi > html/lit2mobi.html
	pod2html opf2mobi > html/opf2mobi.html
	pod2html html2mobi > html/html2mobi.html


copy:
	scp $(TARFILE) html/*.html index.html remote.ida.liu.se:www-pub/mobiperl/downloads/

copyhtml:
	scp index-html html/*.html remote.ida.liu.se:www-pub/mobiperl/


hm:
	pp -M FindBin -M Palm::PDB -M Palm::Doc -M Date::Format -M Getopt::Mixed -M Image::Size -M Image::BMP -M MobiPerl::MobiHeader -M MobiPerl::MobiFile -M MobiPerl::Opf -M MobiPerl::Config -M MobiPerl::LinksInfo -M XML::Parser::Lite::Tree -M Data::Dumper -M GD -M HTML::TreeBuilder -o html2mobi.exe html2mobi
	copy html2mobi.exe c:\Perlb820\bin\

om:
	pp -M FindBin -M Palm::PDB -M Palm::Doc -M Date::Format -M Getopt::Mixed -M Image::Size -M Image::BMP -M MobiPerl::MobiHeader -M MobiPerl::MobiFile -M MobiPerl::Opf -M MobiPerl::Config -M MobiPerl::LinksInfo -M XML::Parser::Lite::Tree -M Data::Dumper -M GD -M HTML::TreeBuilder -o opf2mobi.exe opf2mobi
	copy opf2mobi.exe c:\Perlb820\bin\

lm:
	pp -M FindBin -M Palm::PDB -M Palm::Doc -M Date::Format -M Getopt::Mixed -M Image::Size -M Image::BMP -M MobiPerl::MobiHeader -M MobiPerl::MobiFile -M MobiPerl::Opf -M MobiPerl::Config -M MobiPerl::LinksInfo -M XML::Parser::Lite::Tree -M Data::Dumper -M GD -M HTML::TreeBuilder -o lit2mobi.exe lit2mobi
	copy lit2mobi.exe c:\Perlb820\bin\


mm:
	pp -M FindBin -M Palm::PDB -M Palm::Doc -M Date::Format -M Getopt::Mixed -M Image::Size -M Image::BMP -M MobiPerl::MobiHeader -M MobiPerl::MobiFile -M MobiPerl::Opf -M MobiPerl::Config -M MobiPerl::LinksInfo -o mobi2mobi.exe mobi2mobi
	copy mobi2mobi.exe c:\Perlb820\bin\

mh:
	pp -M FindBin -M Palm::PDB -M Palm::Doc -M Date::Format -M Date::Parse -M Getopt::Mixed -M Image::Size -M Image::BMP -M MobiPerl::MobiHeader -M MobiPerl::MobiFile -M MobiPerl::Opf -M MobiPerl::Config -M MobiPerl::LinksInfo -o mobi2html.exe mobi2html
	copy mobi2html.exe c:\Perlb820\bin\

all:	hm om lm mm mh

pack:
	"c:\Program Files\WinRAR\rar" a $(RARFILE) html2mobi.exe opf2mobi.exe lit2mobi.exe mobi2mobi.exe mobi2html.exe $(TARFILE)

