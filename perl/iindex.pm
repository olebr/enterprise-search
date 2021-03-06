package iindex;   
require Exporter;
@iindex::ISA = qw(Exporter);
@iindex::EXPORT = qw();
@iindex::EXPORT_OK = qw(WriteIIndexToFile add new);

use constant DictionaryAdressSizeForTerm => 'L L ';						#templaten som brukes p� $adress,$SizeForTerm i DictionaryHash og i DictionaryTemplate
use constant DictionaryTemplate => 'L' . DictionaryAdressSizeForTerm;
use constant DictionaryRecordSize => 12; #st�relsen p� hver ordbok record

use constant AntallBarrals => 64; # m� v�re lik som i revindex.pm

#poneger for plasseringenr i dokumeneter
use constant poengBody => 4;		#4
use constant poengHeadline  => 10;	#10
use constant poengTittel  => 15;	#15
use constant poengUrl  => 60;		#60

use POSIX;
use common qw(MakePath);
use StringPop;

use Boitho::Lot;

#new funksjon
sub new {
	my($class) = @_;
	#my $class = '';
	my $self = {}; #allocate new hash for objekt
	
	$self->{'AntallIIndexElementer'} = 0;	#oversikt over hvor mange elemeneter vi har i minne
		
	bless($self, $class);

	return $self;
}

sub add {
	my($self,$sprok,$DocID,$WordID,$antall,$HitList) = @_;
	
	#push(@{ $self->{'iindex'}->{$WordID} },pack("L L L$antall",$DocID,$antall,$HitList));



	
	${ $self->{'iindex'}->{$sprok}->{$WordID} }[$#{ $self->{'iindex'}->{$sprok}->{$WordID} } +1][0] = $antall;
	${ $self->{'iindex'}->{$sprok}->{$WordID} }[$#{ $self->{'iindex'}->{$sprok}->{$WordID} }][1] = $DocID;
	${ $self->{'iindex'}->{$sprok}->{$WordID} }[$#{ $self->{'iindex'}->{$sprok}->{$WordID} }][2] = $HitList;
	
#	print "$WordID ($self->{'AntallIIndexElementer'}): $#{ $self->{'iindex'}->{$sprok}->{$WordID} }\n";	
	
	#print "nn: $DocID,$antall\n";
	
	$self->{'AntallIIndexElementer'}++;
}

sub WriteIIndexToFile {
	my($self,$type,$revindexFilNr,$lotNr,$subname) = @_;

	
	foreach my $sprok (keys %{ $self->{'iindex'} }) {
	
		#lagrer p� samme plass som lot med samme nr
		#my $LotPath = Boitho::Lot::GetFilePathForIindex($revindexFilNr);
		
		my $LotPath = Boitho::Lot::GetFilPathForLot($lotNr,$subname);
		#fjerner / p� slutten
		chop($LotPath);

		#print "LotPath for $revindexFilNr: $LotPath\n";

		#5: my $indexPath = "data/iindex/$type/index/$sprok";
		my $indexPath = "$LotPath/iindex/$type/index/$sprok";
		if (not -e $indexPath ) {	#sjekker og eventuel lager pathen.
			#print "oppretter path $indexPath\n";
			MakePath($indexPath);
		}
		$fil = $indexPath  . '/' . $revindexFilNr . '.txt';
		open(IINDEX,">$fil") or die("Can't open $fil: $!");
		binmode(IINDEX);
	
		
		#5: $DictionaryPath  = "data/iindex/$type/dictionary/$sprok";
		$DictionaryPath  = "$LotPath/iindex/$type/dictionary/$sprok";
		if (not -e $path_komet_til) {	#sjekker og eventuel lager pathen.
			#print "oppretter path $DictionaryPath\n";
			MakePath($DictionaryPath);
		}
		$fil = $DictionaryPath   . '/' . $revindexFilNr . '.txt';
		open(IDICTIONARY ,">$fil") or die("Can't open $fil: $!");
		binmode(IDICTIONARY);
	
		#print "indexPath $indexPath, DictionaryPath $DictionaryPath\n";
		foreach my $term (sort {$a <=> $b} keys %{ $self->{'iindex'}->{$sprok} }) { # {$a <=> $b} f�r � sortere numerisk, ikke alfabetisk etter ASCII som er perl standar.
		
			my $AntallSiderMedTerm = scalar(@{ $self->{'iindex'}->{$sprok}->{$term} });
		
			%TermHash = ();
			
			foreach my $i (@{ $self->{'iindex'}->{$sprok}->{$term} }) {
			
			
				#legger datane inn i en hash
				if (exists $TermHash{$i->[1]}) {
					#print "$i->[1] fins fra f�r\n";
					#exit;
					
					#hvis vi allerede har info om denne docIDen skal vi legge til hitliste og �ke antall hitt
					${ $TermHash{$i->[1]} }[0] += $i->[0]; #legger til antall
                                        ${ $TermHash{$i->[1]} }[1] .= $i->[2];    #legger til hit list
				}	
				else {
					${ $TermHash{$i->[1]} }[0] = $i->[0]; #legger til antall
					${ $TermHash{$i->[1]} }[1] = $i->[2];	#legger til hit list
				}		
			}

			my $countAntall = keys %TermHash;

			print IINDEX pack('L L',$term,$countAntall);

			#debug: viser hva vi har av treff
			#print "term $term, antall $countAntall\n";
			#sorterer p� DocID og lager index
			foreach my $DocID (sort {$a <=> $b} keys %TermHash) {
					

				#temp: div tall tester			
				if (${ $TermHash{$DocID} }[0] =~ /\D/) {
        				die "not a number";
				}
				if (${ $TermHash{$DocID} }[0] > 10000) {
					print "lager then n: ${ $TermHash{$DocID} }[0]\n";
				}
				if (${ $TermHash{$DocID} }[0] < 1) {
                                        print "smaler then 1: ${ $TermHash{$DocID} }[0]\n";
                                }

				#print IINDEX pack('L L',$DocID,${ $TermHash{$DocID} }[0]);
				#14 may. spr�k st�tte
				print IINDEX pack('L A L',$DocID,0,${ $TermHash{$DocID} }[0]);

				print IINDEX ${ $TermHash{$DocID} }[1]; #legger til hit list
					
				#debug: viser ting
				#print "\tDocID: $DocID antall: ${ $TermHash{$DocID} }[0]\n";
			
			}
			
			#legger til info om wordid og antall sider
			
			
		
			#print " SizeForTerm: $SizeForTerm ";
			#print "\n\n";

			#temp, dette fungerer ikke. Bruk tell f�r og etter for � finne lengden		
			my $adress = tell(IINDEX) - $SizeForTerm;
			#print IDICTIONARY "$term $adress:$SizeForTerm\n";
			print IDICTIONARY pack(DictionaryTemplate,$term, $adress, $SizeForTerm);
		}
	
		close(IINDEX);
		close(IDICTIONARY);
	
		print "AntallIIndexElementer $self->{'AntallIIndexElementer'}\n";
	}
}

##########################################################################################
# Laster ordboken inn i en hash
#
#	$self->{'DictionaryHash'}->{WordID} holder hele ordboken
# 	mapper WordID til adresse og st�relse
#	Adresse og st�relse lagres i f�lge konstanten DictionaryAdressSizeForTerm 
##########################################################################################
sub HashLodeDictionary {
	my($self) = @_;
	
	use File::Find;
	
	#$self->%DictionaryHash = {};
	$self->{'DictionaryHash'} = {};
	
	my %options = (wanted => \&list_filer, no_chdir=>1);

	find(\%options,'data/iindex');

	
	sub list_filer {
	
		if (!(-d $File::Find::name)) {
			#push(@languages,$File::Find::name);
			
			#print "$File::Find::name\n";
			#hvis vi har en ordbok fil, som da skal ha "dictionary_" i seg
			if ($File::Find::name =~ /dictionary_/) {
					print "aa: $File::Find::name " . keys(%{ $self->{'DictionaryHash'} }) . "\n";
				
					#$dictionary_fil  = 'data/iindex/dictionary_' . $revindexFilNr . '.txt';
					open(IDICTIONARY ,"$File::Find::name") or die("Can't open dictionary $fil: $!");
					binmode(IDICTIONARY);
					
					local $/ = "**\cJ";
					
					my @inn = <IDICTIONARY>;
				
	
					foreach my $i (@inn) {
						chomp($i);
						my ($WordID, $adress, $SizeForTerm) = unpack(DictionaryTemplate, $i);
					
						#print "$WordID, $adress, $SizeForTerm\n";
						
						$self->{'DictionaryHash'}->{$WordID} = pack(DictionaryAdressSizeForTerm,$adress,$SizeForTerm);
					}
	
					close(IDICTIONARY);
			}
		}
	}
exit;
}
##########################################################################################
# Leser fra indeksen
#
#	bruker $self->{'DictionaryHash'}->{WordID} for � finne adresse og st�relse
##########################################################################################
sub ReadIIndexRecordOLD {
	my($self,$WordID) = @_;

	#print "WordID $WordID" $self->{'DictionaryHash'}->{$WordID} . "\n";
	
	if (exists $self->{'DictionaryHash'}->{$WordID}) {
		my ($adress,$SizeForTerm) = unpack(DictionaryAdressSizeForTerm,$self->{'DictionaryHash'}->{$WordID});
	
		#print "WordID: $WordID, adress: $adress, SizeForTerm: $SizeForTerm\n";
	
		$revindexFilNr = fmod($WordID,AntallBarrals);
		my $fil = 'data/iindex/' . $revindexFilNr . '.txt';
	
		open(IINDEX,"$fil") or die("Can't open $fil: $!");
		binmode(IINDEX);
		
		seek(IINDEX,$adress,0);
	
		read(IINDEX,$inn,$SizeForTerm);
	
		close(IINDEX);
	
		#print "IINDEX: -$inn-\n";
	
		#my ($k,$j,$i) = unpack('L L S', $inn);

		#print "$k,$j,$i\n";
		return $inn;
	}
	else {
		return undef;
	}
}
##########################################################################################
# Bin�rs�ker seg fram til � leser en post fra en index
#
##########################################################################################
sub ReadIIndexRecord {
	my($self,$type,$sprok,$Query_WordID) = @_;
	
	
	#print "L:" . unpack('L',pack('L',$Query_WordID)) . "\n";
	#print "S�ker for $Query_WordID\n";
	#finner riktig fil
	my $revindexFilNr = fmod($Query_WordID,AntallBarrals);
	
	my $dictionary_fil  = "data/iindex/$type/dictionary/$sprok/$revindexFilNr.txt";
	
	#pr�ver � opne filer i tmpfs 
	open(IDICTIONARY ,"tmpfs/$dictionary_fil") or open(IDICTIONARY ,"$dictionary_fil") or die("Can't open dictionary $dictionary_fil: $!");
	binmode(IDICTIONARY);
		
	#print "Antall_poster: $halvert i fil $dictionary_fil\n";
	
	my $max = (stat(IDICTIONARY))[7] / DictionaryRecordSize;;
	my $min = 0;
	
	#print "\tmin: $min, max: $max, halvert: $halvert\n";
	
	
	#bin�rs�k
	my $seeks = 0;
	my $fant = 0;
	#if (0) {
	while ((($max - $min) > 1) && (not $fant)) {
	
		$halvert = floor(((($max - $min) / 2) + $min));
		$posisjon = $halvert * DictionaryRecordSize;
	
		#print "\tmin: $min, max: $max, halvert: $halvert\n";
	
		seek(IDICTIONARY,$posisjon,0);
	
		read(IDICTIONARY,$post,DictionaryRecordSize);
	
		($WordID, $adress, $SizeForTerm) = unpack(DictionaryTemplate,$post);
	
	
		if ($Query_WordID == $WordID) {
			#print "fant $WordID\n";
			#last;
			$fant = 1;
			#exit;
		}
		elsif ($Query_WordID > $WordID) {
			#print "$Query_WordID > $WordID\n";
			$min = $halvert;
		}
		elsif ($Query_WordID < $WordID) {
			#print "$Query_WordID < $WordID\n";
			$max = $halvert;
		}
		
		
		#print "$WordID, $adress, $SizeForTerm\n";
		#exit;
		$seeks++;
		
		if ($seeks == 50) {
			die("brukte mere en 50 seeks p� � finne record i dictonary");
		}
	
	}
	
	
	
	#print "prukte $seeks fors�k\n";
	
	close(IDICTIONARY);
	#}
	#print "WordID: $WordID, adress: $adress, SizeForTerm: $SizeForTerm\n";
	#$WordID = 365508689;
	#$adress = 1189918;
	#$SizeForTerm = 1040162;
	#$fant = 1;
	
	#hvis vi fant noe sl�r vi opp i indeksen og leser inn indeksen
	if ($fant) {
		#$revindexFilNr = fmod($WordID,AntallBarrals);
		my $fil = "data/iindex/$type/index/$sprok/$revindexFilNr.txt";
	
		#print "adress: $adress, SizeForTerm: $SizeForTerm\n";
		
		open(IINDEX,"$fil") or die("Can't open $fil: $!");
		binmode(IINDEX);
		seek(IINDEX,$adress,0);
	
		read(IINDEX,$inn,$SizeForTerm);
	
		close(IINDEX);
	
		#print "IINDEX: -$inn-\n";
	
		#my ($k,$j,$i) = unpack('L L S', $inn);

		#print "$k,$j,$i\n";
		return $inn;
	}
	else {
		return undef;
	}
	
	#exit;
}

##########################################################################################
# Returnerer en array med termner, forekomster og posisjoner for enkelt ord. 
#
#	Inn:
#	WordID
#
#	return
#	string	-Antall sider som har dette treffe
#	array
#		DocID	- DocID for en side som har dette orde i seg
#		Antall	- Antall treff p� den siden
#		Hitt	- Array med posisjoner
#	bruker $self->{'DictionaryHash'}->{WordID} for � finne adresse og st�relse
##########################################################################################
sub GetIndexAsArray {
	my($self,$type,$sprok,$WordID) = @_;

	my $RawIndex = $self->ReadIIndexRecord($type,$sprok,$WordID);
	## temp ##
	#print "\nSekuensielt s�k: \n";
	#$self->ReadIIndexRecordMedSekuensiseltSeach($WordID);
	#exit;
	# /temp ##
	
	if ($RawIndex ne undef) {
		#print "RawIndex: -$RawIndex-\n";
		my @treffArray = ();
		
		my $indexLengde = length($RawIndex);
	
	
		$StringPopHa = StringPop->new($RawIndex);

		my ($term,$AntallTreff) = unpack('L L',$StringPopHa->Pop(8));
	
		#print "\nterm: $term, AntallTreff: $AntallTreff\n";
		#loper gjenom hele indeksen
		my $lest = 8;
		while ($indexLengde > $lest) {
			my ($DocID,$Antall) = unpack('L L',$StringPopHa->Pop(8));

			my @hits = unpack('S' x $Antall,$StringPopHa->Pop($Antall * 2));
	
			#print "$DocID,$Antall\n";
	
			$lest = $lest + 8 + ($Antall * 2);
	
			#for hver hitt do:
			#foreach my $i (@hits) {
			#	print "\thit: $i\n";
			#}
		
			#for hver hitt legger til poeng:
			my $poeng = 0;
	
			my $urlPoeng = 0;
			#my %points = ();
			foreach my $i (@hits) {
				
				if ($i <= 100) {
					$poeng = $poeng + poengUrl;
				}
				elsif ($i <= 500) {
					$poeng = $poeng + poengTittel;
				}
				elsif ($i <= 1000) {
					$poeng = $poeng + poengHeadline;
				}
				else {
					$poeng = $poeng + poengBody;
				}
				#if ($i >= 1000) {	#Body
				#	$poeng = $poeng + poengBody;
				#	#$points{'poengBody'} = $points{'poengBody'} + poengBody;
				#	#$points{'AntallBody'}++;
				#}
				#elsif ($i >= 500) {	#Headline
				#	$poeng = $poeng + poengHeadline;
				#	#$points{'poengHeadline'} = $points{'poengHeadline'} + poengHeadline;
				#	#$points{'AntallBody'}++;
				#}
				#elsif ($i >= 100) {	#Tittel
				#	$poeng = $poeng + poengTittel;
				#	#$points{'poengTittel'} = $points{'poengTittel'} + poengTittel;
				#	#$points{'AntallHeadline'}++;
				#}
				#elsif ($i >= 0) { #Url
				#	$poeng = $poeng + poengUrl;
				#	#$points{'poengUrl'} = $points{'poengUrl'} + poengUrl;
				#	#$points{'AntallUrl'}++;
				#	#$urlPoeng = $urlPoeng + poengUrl;
				#	print "aaaa\n";
				#}
				#else {
				#	warn("Ukjent posisjon $i");	
				#}
			}
			
			#my $poeng = 0;
			
			
			#if ($urlPoeng != 0) {
			#	$poeng += ($urlPoeng / (((log ($urlPoeng / poengUrl)) * 10) +1));
			#	#print "$poeng += ($points{'poengUrl'} / (((log $points{'AntallUrl'}) * 10) +1))\n"
			#}
			
			$treffArray[$#treffArray +1][0] = $DocID;
			$treffArray[$#treffArray][1] = $Antall;
			$treffArray[$#treffArray][2] = \@hits;
			$treffArray[$#treffArray][3] = $poeng;
			$treffArray[$#treffArray][4] = 0; #link vekt
		}
		
		return $AntallTreff,@treffArray;
	}
	else {
		return undef;
	}
	
}

##########################################################################################
# Sorterer en indeks array etter poeng
#
##########################################################################################
sub SortIndexArrayByPoints {
	my($self,@Array) = @_;
	
	@Array = sort {$a->[3] <=> $b->[3] } @Array;
	@Array = reverse(@Array);
	
	return @Array;
}
