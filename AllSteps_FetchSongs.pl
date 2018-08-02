#!/usr/bin/perl
 
#use strict;
#use warnings;
use LWP::Simple;
use utf8;
use Term::Screen;
use Term::RawInput;
use WWW::Mechanize;
use Data::Dumper;
use HTML::TreeBuilder;
use HTML::Entities;
use URI::Encode;
use File::Slurp;
use Try::Tiny;
use File::Find qw(finddepth);
use File::Slurper qw(read_text);
use File::Copy qw(copy);
use Encode::Encoder;
use Cwd;
use XML::LibXML;

require Data::Dumper;
require WWW::Mechanize;
require HTML::TreeBuilder;

#PARAMETERS

my @USER_AGENTS = (
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) ',
    'Chrome/52.0.2743.116 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.82 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:46.0) Gecko/20100101 Firefox/46.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:47.0) Gecko/20100101 Firefox/47.0'
);
my $agent = $USER_AGENTS[rand @USER_AGENTS];
my $mech = WWW::Mechanize->new($agent);
my $uri     = URI::Encode->new( { encode_reserved => 0 } );
my $ccli_BASE_URL = 'https://songselect.ccli.com';
my $ccli_LOGIN_PAGE = 'https://profile.ccli.com/account/signin?appContext=SongSelect&returnUrl=https%3a%2f%2fsongselect.ccli.com%2f';
my $ccli_LOGIN_URL = 'https://profile.ccli.com';
my $ccli_LOGOUT_URL = $ccli_BASE_URL . '/account/logout';
my $ccli_SEARCH_URL = $ccli_BASE_URL . '/search/results';

my $username = 'your_username';
my $password = 'your_password';

my $mode = "";
my $link = "";


# MAIN

main();

# Subroutins

sub main(){


	if (scalar @ARGV >= 2) {
		$mode = $ARGV[0];
		$link = $ARGV[1];
		print "\n\n";
		print "**********************************************************************\n";
		print "**                         CCLI Song Fetcher                        **\n";
		print "**********************************************************************\n";
		print "  Parameter ubergeben: Nutze Schritt $mode mit dem Link $link\n\n";
		print "**********************************************************************\n";
	} elsif (scalar @ARGV >= 1) {
		$mode = $ARGV[0];
		if ($mode==4 or $mode==5){		
		print "\n\n";
		print "**********************************************************************\n";
		print "**                         CCLI Song Fetcher                        **\n";
		print "**********************************************************************\n";
		print "  Parameter ubergeben: Nutze Schritt $mode\n\n";
		print "**********************************************************************\n";
		} else {
			print q{don't have parameters};
		}
	} else {
		print q{don't have parameters};
	}
	
	
		
	while ($mode==0) {
	
		my $scr = new Term::Screen;	
		unless ($scr) { die " Something's wrong \n"; }
		$scr->clrscr();
		
		printMenu();
		
		my $keystroke = '';
		my $special = ''; 

		while($mode==0  && lc($keystroke) ne 'c'){

			my $promptp = "Your choice: ";

			($keystroke,$special) = rawInput($promptp, 1);

			if ($keystroke ne '') {
				print "You hit the normal '$keystroke' key\n";
			} else {				
				print "You hit the special '$special' key\n";
			}
									
			if ($keystroke == "c"){
				print "Thank you for usage!\n\n";
				exit;
			}			
			if ($keystroke == "1"){
				$mode = 1;
			}
			if ($keystroke == "2"){
				$mode = 2;
			}
			if ($keystroke == "3"){
				$mode = 3;
			}
			if ($keystroke == "4"){
				$mode = 4;
			}
			if ($keystroke == "5"){
				$mode = 5;
			}

			chomp($keystroke);

			$keystroke = lc($keystroke);
		}
											
	}
	
	print "\n\n";
	
	if ($mode == 1){
		print "Von welcher Seite von www.liederdatenbank.de sollen die Lieder geladen werden?\n";
		print "Seite: ";
		$link = <STDIN>;
		$link = trim($link);
		Step01();
	}
	if ($mode == 2){
		print "Aus welcher Datei sollen die Lieder verlinkt werden (*.csv)?\n";
		print "Datei: ";
		$link = <STDIN>;
		$link = trim($link);
		Step02();
	}
	if ($mode == 3){
		print "Welche Datei soll heruntergeladen werden (*.csv)?\n";
		print "Datei: ";
		$link = <STDIN>;
		$link = trim($link);
		Step03();
	}	
	if ($mode == 4){
		Step04();
	}
	if ($mode == 5){
		Step05();
	}
	
	print "\n\n";
	print "**********************************************************************\n";
	print "             Script beendet!\n\n";
	print "**********************************************************************\n";
}
  
sub printMenu(){
	print "**********************************************************************\n";
	print "**                         CCLI Song Fetcher                        **\n";
	print "**********************************************************************\n";
	print "**  Bitte einen Schritt wahlen oder Esc zum beenden druecken        **\n";
	print "**                                                                  **\n";
	print "**       1 - Alle Lieder der eing. Seite exportieren                **\n";
	print "**       2 - Passende Lieder auf CCLI zuordnen                      **\n";
	print "**       3 - Lieder von CCLI im USR Format exportieren              **\n";
	print "**       4 - CSV aller Lieder erzeugen                              **\n";
	print "**       5 - Liederdatenbank erzeugen                               **\n";
	print "**       c - Programm beenden                                       **\n";
	print "**                                                                  **\n";
	print "**                               (C) Christian Beckert 2017, 2018   **\n";
	print "**********************************************************************\n";
}

# SCHRITT 1
sub Step01() {
	#Quelltext geladen
	my $flname = "";
	
	if (begins_with($link, "http://www.liederdatenbank.de") or begins_with($link, "https://www.liederdatenbank.de")) {
	
		$flname = "Step1_Songs_" . substr($link, 29, length($link)) . ".csv";
		$flname = $flname =~ s/\///rgm;
		
		#print "$flname\n\n";
			
		$mech->add_header( 'User-agent' => $agent);
		$mech->cookie_jar(HTTP::Cookies->new());
		$mech->get($link);
		
		my $quelltext = $mech->content();

		#Datei
		my $filename1 = "log_$flname.txt";
		open(my $fh1, '>:encoding(UTF-8)', $filename1) or die "Could not open file '$filename1' $!";
		open(my $fh2, '>:encoding(UTF-8)', $flname) or die "Could not open file '$flname' $!";
		 
		my @array1;
		@array1 = ($quelltext =~ /(?m)<a href="\/song\/(.*?)">(.*?)<\/a>/g);

		for(my $i = 0; $i < @array1; $i=$i+2) {

			my $songbnumber = $array1[$i];
			my $songbname = $array1[$i+1];
			
			my $cclinumber = "-1";			
			my $songname = $songbname;
			my $author=""; 
			
			my $newURL = "http://www.liederdatenbank.de/song/$songbnumber";			
			# TEST: my $quelltext_song = "asdfasdfsadf<a href=\"https://de.songselect.com/songs/5841479\">Lied 5841479 in SongSelect</a>asdfasdfasdfasdf" ;#get($newURL);
			my $quelltext_song = get($newURL);
			#utf8::decode($quelltext_song);

			@array2 = ($quelltext_song =~ /(?m)<a href="https:\/\/de.songselect.com\/songs\/(.*?)">/g);
			@array3 = ($quelltext_song =~ /(?m)<a href="\/artist\/(\d*?)">(.*?)<\/a>/g);  #  <a href="/artist/2772">Arne Kopfermann</a>
			
			for(my $x = 0; $x < @array3; $x=$x+1) {
				if ($x % 2 == 1) {
					$author .= $array3[$x];
					$author .= " | ";
				}			
			}
			
			if (length($author)>3) {
				$author = substr($author,0,-3);
			}
			
			for(my $c = 0; $c < @array2; $c=$c+2) {
				$cclinumber = $array2[$c];			
				$songname = $songbname;
				#$songname =~ s/\s/-/g;
				#$songname =~ s/,//g;
				#$songname =~ s/'//g;				
				#$songname =~ s/\///g;
				#$songname =~ s/\!//g;
				#$songname =~ s/\?//g;			
				#$songname =~ s/ä/a/g;
				#$songname =~ s/ö/o/g;
				#$songname =~ s/ü/u/g;
				#$songname =~ s/Ä/A/g;
				#$songname =~ s/Ö/O/g;
				#$songname =~ s/Ü/U/g;
				#$songname =~ s/ß/s/g;
				#$songname =~ s/://g;
				#$songname = lc $songname;		
				
			}
			
			print "  -Fetch Song from $newURL:\n";
			if ($cclinumber != -1)	{	
				print "   Number:    $cclinumber\n";
			}
			print     "   Name:      $songbname\n";
			print     "   Author:    $author\n";
			
			print $fh1 "  -Fetch Song from $newURL:\n";
			if ($cclinumber != -1)	{	
				print $fh1 "   Number:     $cclinumber\n";
			} else {
				print $fh1 "   Number:     Keine CCLI-Nummer angegeben\n";
			}
			print     $fh1 "   Name:       $songbname\n";
			print     $fh1 "   Author:     $author\n";
								
			
			print $fh2 "$cclinumber;$songname;$author\n";
				
			
		}
		
		print $fh2 "";
	} else {
		print "FEHLER: der angegebenen Link verweist nicht auf die Seite www.liederdatenbank.de oder beginnt nicht mit http:// oder https://www.liederdatenbank.de an!\n";
		$flname = "-1";
	}
	
	return $flname;
	
}


# SCHRITT 2
sub Step02() 
{
	if (find_endung($link) ne "csv") {
		print "FEHLER: Die Datei die uebergeben wurde ist keine CSV Datei!\n\n";
		return "-1";
	} 
	if (!begins_with($link, "Step1_") ) {
		print "FEHLER: Die Datei muss mit 'Step1_' beginnnen!\n\n";
		return "-1";
	} 
	
	
	print "Datei $link wird nun gescannt!\n";
	
	#login();

	open(my $csvdata, '<:encoding(UTF-8)', $link) or die "Could not open '$link' $!\n";
	open(my $fh, '>:encoding(UTF-8)', 'Step2_downloadlfor_' . $link);

	my $counter = 0;
	my $triedsimple = 0;
	while (my $line = <$csvdata>) {
		$counter ++;
		$triedsimple = 0;
	 		
		my @fields = split ";" , $line;
		my $cclinumber = $fields[0];
		my $songtitle = $fields[1];
		my $ats = $fields[2];
		
		chomp $line;
				
		my @autors =
		sort(
			map {
					s/^\s+|\s+$//g; $_
				}
				split '\|', $fields[2]
		); 
		$linecnt = scalar @autors;		
						
		print "  - Suche nach '$songtitle' von $ats";
	  
	  
		# --suche
		if ($counter > 1000) {
			close $fh;
			return;
		
		}
				
		my $foundamatchingsong = "nein";
		my $foundabestmatchingsong = "nein";
		my $importall = "nein";
		
		SCANNSTEP:
		
		$mech->add_header( 'User-agent' => $agent);	
		my $searchurl = $ccli_SEARCH_URL . "?SearchText=" . $uri->encode($songtitle);		
		print "    URL: $searchurl\n";
		
		
		$mech->get($searchurl);
		my $tree_songresult = HTML::TreeBuilder->new_from_content($mech->content);
		
		#my $string = read_file("page.html");
		#my $tree_songresult = HTML::TreeBuilder->new_from_content($string);
		
		my @songresults = $tree_songresult->look_down(_tag  => 'div', class => 'song-result');
							
		if (scalar @songresults > 0) {
			$cnt = scalar @songresults;
			print "    $cnt Ergebniss(e)!\n";
			
			
			foreach my $songresult (@songresults) {
				
				#Ergebnisse abholen
				$fnd_title = ($songresult->look_down(_tag  => 'p', class => 'song-result-title'))->as_text();				
				$fnd_author = ($songresult->look_down(_tag  => 'p', class => 'song-result-subtitle'))->as_text();
				$fnd_author = $fnd_author =~ s/,/|/r;
				$fnd_link = ($songresult->look_down(_tag  => 'p', class => 'song-result-title'))->look_down(_tag  => 'a')->attr('href');
				$fnd_cclinum = ($fnd_link =~ /(?m)\/(\d*?)\//g)[0];
				
				#Importieren zurucksetzen
				my $importactresult = "nein";
				
				#Suche ob die CCLI nummer passt --> dann wird nicht mehr weiter gescannt!
				if ($cclinumber==$fnd_cclinum){
					$importactresult = "ja";
					$foundabestmatchingsong = "ja";
				
				#Wenn noch kein passendes Lied gefunden wurde dann suche nach dem Autor
				} elsif ($foundabestmatchingsong eq "nein")  {
					foreach my $at (@autors) {
						$at = trim($at);
						if (index($fnd_author, $at) != -1) {
							$importactresult = "ja"; #Autor passt ,Lied kann importiert werden!
						}
					}
				}
														
				
				if ($importactresult eq "ja" or $importall eq "ja") {
					print "    Gefunden: $fnd_title von\n    $fnd_author\n     Link $fnd_link)\n       --> Import ja\n";
					$foundamatchingsong = "ja";
					print $fh substr($line,0,-2) . ";$fnd_cclinum;$fnd_title;$fnd_author;$ccli_BASE_URL$fnd_link\n";
				} 
				
			}
						
		} 
		
		#Wenn noch kein Lied iportiert wurde oder keine Ergenisse zum Lied voralgen dann versuche die vereinfachte Methode
		if ($triedsimple == 0 and $foundamatchingsong eq "nein") {
			print "    Keine Ergebnisse - Songtitel wird nun vereinfacht versucht!\n";
			$songtitle =~ s/\((.*?)\)//g;
			$triedsimple = 1;
			goto SCANNSTEP;				
		}
		
		#Das Lied wurde eventuell gar nicht gefunden
		if ($foundamatchingsong eq "nein"){
			$foundamatchingsong = "ja";	#setze das zeichen das bereits ein passender Song gefunden wurde!
			$importall = "ja";
			goto SCANNSTEP;	
			print $fh substr($line,0,-2) . ";-1;\n";
		}
		
	}
}

# SCHRITT 3
sub Step03()
{
	if (find_endung($link) ne "csv") {
		print "FEHLER: Die Datei die uebergeben wurde ist keine CSV Datei!\n\n";
		return "-1";
	} 
	
	if (!begins_with($link, "Step2_") ) {
		print "FEHLER: Die Datei muss mit 'Step2_' beginnnen!\n\n";
		return "-1";
	} 
	
	print "Datei $link wird nun heruntergeladen!\n";
	
	login();

	open(my $csvdata, '<:encoding(UTF-8)', $link) or die "Could not open '$link' $!\n";
	my $counter = 0;
	
	mkdir "Step3_Download";
	chdir "Step3_Download";
	
	my $errors;
	while ($_ = glob('*.*')) {
		next if -d $_;
		unlink($_) or ++$errors, warn("Can't remove $_: $!");
	}


	while (my $line = <$csvdata>) {
		$counter ++;
		
		if ($counter<500){		
			chomp $line;
			
			try{
		 
				my @fields = split ";" , $line;
				
				if (scalar(@fields)>6){			
					my $cclinumber = $fields[3];
					my $songtitle = $fields[4];
					my $ats = $fields[5];
					my $page = $fields[6] . "/viewlyrics";
					
					
					if ($fields[6]==-1){
						print "   -Skip the Line  '$line' from the CSV File\n"
					} else {					
						#$page =~ s/-1//r;
												
						$ats =~ s/,|;/|/g;
						
						$mech->add_header( 'User-agent' => $agent);
						$mech->get($page);
						
						my $output_page = $mech->content();										
						my $tree_pg = HTML::TreeBuilder->new_from_content($mech->content);
						
						#open(my $tmp, '>:encoding(UTF-8)', "tmp.txt");
						#print $tmp $output_page;
						#close $tmp;
						
						#my $string = read_file("testpage.html");
						#my $tree_pg = HTML::TreeBuilder->new_from_content($string);
												
						my $copyright = $tree_pg->look_down(_tag  => 'ul' , class => 'copyright')->as_text();			
						$songtitle = $tree_pg->look_down(_tag  => 'h2', class => 'song-viewer-title')->as_text(); 
						
						print "   -Download '$songtitle' von $ats:\n";			
						
						@songparts = $tree_pg->look_down(_tag  => 'h3', class => 'song-viewer-part');
						my $songparts = "";			
						foreach my $sp (@songparts) {
							$songparts .= trim($sp->as_text()) . "/t";				
						}
						$songparts = substr($songparts,0,-2);
									
						
						$tree_songwords = ($tree_pg->look_down(_tag  => 'div', id => 'song-viewer'));
						my $songwords = "";
						foreach my $atag ($tree_songwords->look_down( _tag => 'h3' ) ) {
							$songwords .= GetWordsFromPart( $atag ) . "/t";
						}
						$songwords = substr($songwords,0,-2);	
									
						my $flname =  "tmpSong_" . $cclinumber . "_" . $songtitle . ".usr";
						
						open(my $fh, '>:encoding(UTF-8)',$flname);
						print $fh decode_entities("[File]\nType=SongSelect Import File\nVersion=3.0\n[S A$cclinumber]\nTitle=$songtitle\nAuthor=$ats\nCopyright=$copyright\nAdmin=$copyright\nThemes=\nKeys=\n");	  
						print $fh decode_entities("Fields=$songparts\n");
						print $fh decode_entities("Words=$songwords\n");
						close $fh;	
						
						

						print "    ok\n";
					}
				} else {
					print "   -Skip the Line  '$line' from the CSV File\n"
				}
			} catch {
				my $e = shift;
				print("FEHLER: beim Scannen der Zeile, Fehler '$e'\n");
			}
		}
	}
	
	chdir "..";
		
}

# SCHRITT 4
sub Step04()
{	
	
	readin();
	copyfiles();
}

# SCHRITT 5
sub Step05()
{		
	my $filenm = 'Step5_Songdatenbank.csv';
	my @dbfiles;

	@dbfiles = readinUSR(@dbfiles);
	@dbfiles = readinXML(@dbfiles);

	#@files = sort_trans_ref (@files);
	@dbfiles = sort { ($a->[0] cmp $b->[0]) } @dbfiles;

	mkdir "Step5_Database";
	chdir "Step5_Database";
	open(my $fh, '>', $filenm) or die "Could not open file '$filenm' $!";

	my $lastTitle = " ";
	for (my $i = 0; $i < @dbfiles; $i++) {
			my $title = $dbfiles[$i][0];
			my $author = $dbfiles[$i][1];		
			my $filename = $dbfiles[$i][2];
			my $id = $dbfiles[$i][3];
			
			if ( lc(substr($lastTitle,0,1)) cmp lc(substr($title,0,1))){
				print $fh substr($title,0,1) . ";\n"  ;
				#print "New Letter: " . substr($title,0,1) . "\n";
				}
			my $textcsv = "'$title' von $author;$id;$title;$author;$filename\n";
			print $fh $textcsv;
			
			$lastTitle=$title;
			
			
		}
	my $cnt = scalar @dbfiles;
	print "$cnt Dateien wurden in die Datenbank aufgenommen!\n";
	close $fh;
	
	chdir "..";
}

sub readinUSR() {
	
	my @temp_files;
	my @dbfiles = @_;
	
	finddepth(sub {
						
		my $result = index($_, ".usr", 0);
		if ($result != -1) {
					
			my $filename = $File::Find::name;				
			#	my $content = read_text( $_ ) or die "could not open file: $!";	
			my $content = do {
				open my $fh, '<:utf8', $_ or die '...';
				local $/;
				<$fh>;
			};
			
			my $title = "nomatch";
			my $id = "nomatch";
			my $author = "nomatch";
			
			utf8::decode($content);
					
			if ($content =~ m/\[S A(\d+)\]/img) {		  	   
				$id = "$1";
			} else {
				$id = "nomatch";
			}
			
			if ($content =~ m/Title=(.*)\n/mg) {		  	   
				$title = $1;
			} else {
				$title = "nomatch";
			}
			
			if ($content =~ m/Author=(.*)\n/mg) {		  	   
				$author = $1;
			} else {
				$author = "nomatch";
			}
					
			if ($id ne "nomatch" && $title ne "nomatch") {	
				$title =~ s/'//g;			
				my @filedata = [				
					"$title",
					"$author",
					"$filename",
					"$id"
				];		
				print "$id : '$title' from $author (Filename: '$filename') \n" ;
				
				#print $textcsv;
				#print $opfile $textcsv;					
				push @dbfiles, @filedata;
			}
		}
						
	}, 'Step4_SortetDownload/');
	
	return @dbfiles;
			
}

sub readinXML() {
	my @dbfiles = @_; 
	
	finddepth(sub {
						
		my $result = index($_, ".xml", 0);
		if ($result != -1) {
				
			my $filename = $File::Find::name;			
			my $title = "nomatch";
			my $id = "nomatch";
			my $author = "";
											
			my $content = do {
				open my $fh, '<:utf8', $_ or die '...';
				local $/;
				<$fh>;
			};
			
			#utf8::decode($content);
						
			$content =~ s/xmlns\=([\S]+)//m;
			
			my $dom = XML::LibXML->load_xml(string => $content);
			
			my $ec = $dom->actualEncoding();
			my $bool = $dom->is_valid();
			my $root = $dom->documentElement();
			my $strVersion = $dom->version();
			
			print "Parsedata File '$_' (encoding $ec, valid $bool, version $strVersion):\n";
						
			foreach my $title2 ($dom->findnodes('/song/properties/titles/title')) {
				$title = $title2->to_literal();
			}
			
			foreach my $title2 ($dom->findnodes('/song/properties/authors/author')) {
				$author = $author . " | " . $title2->to_literal();
			}
			$author = substr($author, 3);
			
			foreach my $title2 ($dom->findnodes('/song/properties/ccliNo')) {
				$id = $title2->to_literal();
			}
						
																	
			if ($id ne "nomatch" && $title ne "nomatch") {		  	   
				$title =~ s/'//g;
				my @filedata = [				
					"$title",
					"$author",
					"$filename",
					"$id"
				];		
				print "$id : '$title' from $author (Filename: '$filename') \n" ;
				
				#print $textcsv;
				#print $opfile $textcsv;					
				push @dbfiles, @filedata;
			} else {
				#no warnings "exiting";
				#next;
			}
		}
						
	}, 'Step4_SortetDownload/');
	
	return @dbfiles;		
}

# HELPERS
sub login()
{
	print "Login on CCLI...";
	$mech->add_header( 'User-agent' => $agent);
	$mech->cookie_jar(HTTP::Cookies->new());
	$mech->get($ccli_LOGIN_PAGE);

	
	$mech->form_number(1);
	$mech->field("EmailAddress", $username);
	$mech->field("Password", $password);
	$mech->submit_form(form_number => 1);

	my $output_page = $mech->content();
	
	my $tree_login = HTML::TreeBuilder->new_from_content($mech->content);
	my $token = ($tree_login->look_down('name', '__RequestVerificationToken'))->attr('value') or die "FEHLER: Wahrscheinlich falscher Login!\n";

	#print "\ngettoken: '$token'\n";
	
	print "...done!\n\n";
	return $token;
}
 
sub readin() {
	
	my @temp_files;

	finddepth(sub {
		
		#return if(($_ eq '.' || $_ eq '..' || $_ eq ''));
		
		$_ eq '.'  and next;
        $_ eq '..' and next;
		my $result = index($_, ".usr", 0);
		if ($result == -1) {
			next;
		}
		
		my $filename = $File::Find::name;				
		#	my $content = read_text( $_ ) or die "could not open file: $!";	
		my $content = do {
			open my $fh, '<:utf8', $_ or die '...';
			local $/;
			<$fh>;
		};
		
		utf8::decode($content);
				
		my $id = "nomatch";
		if ($content =~ m/\[S A(\d+)\]/img) {		  	   
			$id = "$1";
		} else {
			$id = "nomatch";
		}
		
		if ($content =~ m/Title=(.*)\n/mg) {		  	   
			$title = $1;			
			$title =~ s/\n//g;
			$title =~ s/\r//g;
			$title =~ s/^\s+//;
			$title =~ s/\s/-/g;
			$title =~ s/,//g;
			$title =~ s/'//g;				
			$title =~ s/\///g;
			$title =~ s/\!//g;
			$title =~ s/\?//g;			
			$title =~ s/ä/a/g;
			$title =~ s/ö/o/g;
			$title =~ s/ü/u/g;
			$title =~ s/Ä/A/g;
			$title =~ s/Ö/O/g;
			$title =~ s/Ü/U/g;
			$title =~ s/ß/s/g;
			$title =~ s/://g;
		} else {
			$title = "nomatch";
		}
				
		if ($id ne "nomatch" && $title ne "nomatch") {		  	   
			my @filedata = [				
				"$title",
				"$filename",
				"$_",
				"$id"
			];			
			push @temp_files, @filedata;
		}
				
	}, 'Step3_Download/');
	
	$temp_files = sort_array($temp_files);
		
	for (my $i = 0; $i < @temp_files; $i++) {
		my $di = $temp_files[$i][3];
		
		my $hasduplicate = 0;
				
		for (my $x = 0; $x < @files; $x++) {
			my $dx = $files[$x][3];
						
			if ($di == $dx && $x != $i){
				print "duplicate!\n";
				$hasduplicate = 1;
			}
			
		}
		
		if ($hasduplicate==0){
			my $t = $temp_files[$i][0];
			my $p = $temp_files[$i][1];		
			my $d = $temp_files[$i][2];
			my $n = $temp_files[$i][3];
			
			my @filedata = [				
				"$t",
				"$p",
				"$d",
				"$n"
			];			
			push @files, @filedata;
		}
	}
	 		
	for (my $i = 0; $i < @files; $i++) {
		my $t = $files[$i][0];
		my $p = $files[$i][1];		
		my $d = $files[$i][2];
		my $n = $files[$i][3];
				
		print "$i : '$t' has id $n (File: $d Path: $p ) \n" ;
	}	
	
}

sub sort_trans_ref {
    my $transRef = shift;
    @$transRef = sort { lc($a->[0]) cmp lc($b->[0]) } @$transRef;
    return $transRef;
}

sub sort_array {
    my $transRef = shift;
    @$transRef = sort { $a->[1] cmp $b->[1] } @$transRef;
    return $transRef;
}

sub copyfiles {

	mkdir "Step4_SortetDownload";
	my $sortetDirectory = "Step4_SortetDownload/Import/";
	mkdir $sortetDirectory;

	for (my $i = 0; $i < @files; $i++) {
		my $t = $files[$i][0];
		my $d = $files[$i][2];
		my $n = $files[$i][3];
		
		my $from = $files[$i][1];
		my $to = $sortetDirectory."Song_".$n."_".$t.".usr";
				
		print "Copy $from to $to \n" ;
		
		copy $from, $to;
	}
	
}

sub trim($){
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub begins_with{
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub find_endung{
	my $text=shift;
	return if (index($text,'.') == -1);

	(my $endung)=split (/\?/,$text);
	$endung=(split(/\./,$endung))[-1];

	return $endung;
}

sub GetWordsFromPart {
    my ($tag) = @_;
	my $words = "";
    while ( defined( $tag ) and defined( my $next = $tag->right ) ) {
        last if lc $next->tag eq 'h3';
        if ( lc $next->tag eq 'p') {
            $words .= $next->as_XML;
			$words =~ s/<br \/>/\/n/g;
			$words =~ s/<p>|<\/p>|\n//g;
			#print $words;
        }
        $tag = $next;
    }
	
	return $words;
}


