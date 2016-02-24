#!/bin/bash

# serwer synchronizacji
username=USERNAME 
host=HOSTNAME 

# (pod)folder, w którym są pliki do synchronizacji
dir=lab


function show_help {
echo "
 użycie: $0 nazwa_kat
 synchronizuje pliki z katalogu: ./nazwa_kat/$dir ze zdalnym folderem ~/nazwa_kat przez ssh

 wymagana struktura katalogów:


	LAPTOP:
 folder 	<- folder zawierający skrypt
 |
 \--- kat1
 |     \--- $dir
 \--- kat2
 |     \--- $dir
 ...

	Zdalny:
 ~katalog_domowy
 \--- kat1	<- synchronizowany z kat. kat1/$dir na lokalnym komputerze!
 \--- kat2
 ...
"
}

if [ $# -ne 1 ]; then
	show_help
	exit 1
fi


if [ ! -d $1/$dir ]; then
	echo "Folder $1/$dir nie istnieje."
	exit 1
fi

# polecenia rsync
function c2s_test {
	rsync -avn --delete --progress --timeout=600 -e 'ssh -q' $1/$dir/ $username@$host:~/$1
	check_error
}
function c2s_sync {
	echo "Synchronizacja..."
	rsync -av --delete --progress --timeout=600 -e 'ssh -q' $1/$dir/ $username@$host:~/$1
	check_error
}

function s2c_test {
	rsync -avn --delete --progress --timeout=600 -e 'ssh -q' $username@$host:~/$1/ $1/$dir
	check_error
}

function s2c_sync {
	echo "Synchronizacja..."
	rsync -av --delete --progress --timeout=600 -e 'ssh -q' $username@$host:~/$1/ $1/$dir
	check_error
}

function check_error {
	if [ ! $? == 0 ]; then
		echo "BŁĄD! Nie ukończono synchronizacji."
		exit 1
	fi
}

echo -e "\nFOLDER synchronizowany:\t $1/$dir (lokalny) <-> ~/$1 (zdalny)\n"
echo "########################################################################"
echo "   UWAGA! rsync --delete; najpierw rsync DRY RUN - propozycje zmian."
echo "Po zatwierdzeniu - pliki mogą zostać nadpisane/usunięte nieodwracalnie!"
echo -e "########################################################################\n"
echo "Synchronizacja:"
echo "'>' - komputer->serwer"
echo "'<' - serwer->komputer"
read -p "Kierunek synchronizacji ['>' lub '<'] " sync

case $sync in
	">" ) 	c2s_test $1
		read -p "Synchronizować [t/n]? " confirm
		case $confirm in
			[tT]* ) c2s_sync $1
				echo "Wykonano synchronizację.";;
			[nN]* ) echo "Synchronizacja nie została wykonana.";;
			* ) echo "Wybrano złą opcję. Synchronizacja nie została wykonana.";;
		esac;;
	"<" )	s2c_test $1
		read -p "Synchronizować [t/n]? " confirm
		case $confirm in
			[tT]* ) s2c_sync $1
				echo "Wykonano synchronizację.";;
			[nN]* ) echo "Synchronizacja nie została wykonana.";;
			* ) echo "Wybrano złą opcję. Synchronizacja nie została wykonana.";;
		esac;;
	* ) echo "Poprawne opcje: > lub <. Uruchom skrypt jeszcze raz.";;
esac	
