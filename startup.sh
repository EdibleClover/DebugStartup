#!/usr/bin/

## Bash script to set up PHP debugging environment and Nencessary tools:::
##To do, Work eval hook into this somehow, I think itd be easiest to package docker and run it off that since its a dev build of PHP which is annoying to work with.



#Install PHP, DEFAULT TO 7.1
	sudo apt install python-software-properties
	sudo add-apt-repository ppa:ondrej/php
	echo "installing php Version 7.1";
	sudo apt install php7.1
	echo "For more information about installing additional version of php visit:\n https://www.tecmint.com/install-different-php-versions-in-ubuntu/";
	echo php -v

##INSTALL X DEBUG AND MODIFY PHP INI
	echo ":::installing xDebug:::"
		sudo apt-get install php-xdebug
	echo 'checking INI\n'
		iniFile=$(php -r 'echo php_ini_loaded_file();')
	echo "modifying PHP ini @\n ${iniFile}"
	
	sudo echo -e "[XDebug]\n\
		xdebug.remote_enable = 1\n\
		xdebug.remote_autostart = 1\n" >> ${iniFile}
		
##Check and make sure xDebug is listed as a PHP module
	xDebugCheck=$(php -m | grep 'xdebug')
	if [ -z '$xDebugCheck' ]
	then
			echo "Xdebug installation failed\n"
	else
			echo "Xdebug installation succeeded!\n"
	fi
	
echo "xDebug and PHP have been successfully installed!"

echo "Installing Additional tools\n list:\n https://github.com/prettier/plugin-php"
##Lets setup a directory with all of our tools
mkdir ~/Desktop/phpDebug

cd ~/Desktop/phpDebug


## install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

echo 'Composer succesfully installed in Desktop/phpDebug'


##Install pretty Print
php composer.phar require nikic/php-parser

touch PrettyPrint.php
## Create a PrettyPrint File,
echo -e "<?php\n\
use PhpParser\\\\Error;\n\
use PhpParser\ParserFactory;\n\
use PhpParser\PrettyPrinter;\n\
require 'vendor/autoload.php';\n\
\$myFile = \$argv[1];\n
\$code = file_get_contents(\$myFile);\n
\$parser = (new ParserFactory)->create(ParserFactory::PREFER_PHP7);\n\
try {    \$ast = \$parser->parse(\$code);\n\
} catch (Error \$error) {    echo 'Parse error: {\$error->getMessage()}\n';\n\
return;\n\
} \$prettyPrinter = new PrettyPrinter\Standard;\n\
\$prettyCode = \$prettyPrinter->prettyPrintFile(\$ast);\n\
file_put_contents('./cleaned.php', \$prettyCode);" >> PrettyPrint.php


## Create an unFopo file
echo -e "<?php\n\
\$contents = file_get_contents(\$argv[1]);\n\
if (preg_match('/Obfuscation provided by FOPO - Free Online PHP Obfuscator:/',\$contents) === 0) {\n\
	echo '*ERROR: Provided a PHP script not obfuscated with FOPO PHP Obfuscator!';\n\
	exit;\n\
}\n\
\$contents = preg_replace('/\/\/?\s*\*[\s\S]*?\*\s*\/\/?/', '', \$contents);\n\
\$eval = explode('(',\$contents);\n\
//\$base64 = base64 encoded block inside obfuscated PHP script\n\
\$base64 = explode('\"',\$eval[2]);\n\
\$i1 = explode('eval',base64_decode(\$base64[1]));\n\
//there is a ternary operator at this point '?:' -> (condition) ? (expr for TRUE) : (expr 4 FALSE)\n\
//the right data block to be decoded is the second one, that is the data block relative to ':' (FALSE)\n\
\$i2 = explode(':',\$i1[1]);\n\
\$i3 = explode('\"',\$i2[1]); #\$i3[1] = data block passed to decoding chain: gzinflate(base64_decode(str_rot13(\$i3[1])))\n\
//Here final steps with n recursive encoded layers:\n\
//First layer here\n\
\$encodedlayer = gzinflate(base64_decode(str_rot13(\$i3[1])));\n\
//n-1 remaining layers inside while loop below\n\
while (!preg_match('/\?\>/',\$encodedlayer)) {\n\
	\$dl = explode('\"',\$encodedlayer);\n\
	if (sizeof(\$dl)>7) {\n\
	    \$nextlayer = gzinflate(base64_decode(str_rot13(\$dl[7])));\n\
	    \$encodedlayer = \$nextlayer;\n\
	}\n\
	else {\n\
	    \$nextlayer = gzinflate(base64_decode(\$dl[5]));\n\
	    \$encodedlayer = \$nextlayer;\n\
	}\n\
}\n\
//Put it into a file for further analysis\n\
file_put_contents('./cleaned.php', substr(\$encodedlayer, strpos(\$encodedlayer, '?>') + 2, strlen(\$encodedlayer)));\n\
?>" >> unFopo.php



## Install Visual Studio Code!
sudo snap install vscode --classic

##Installe debugger plugin!
sudo code --install-extension felixfbecker.php-debug

## Create a launch JSON for debug plugin
echo -e "\
{\
    'version': '0.2.0',\
    'configurations': [\
        {\
            'name': 'Listen for XDebug',\
            'type': 'php',\
            'request': 'launch',\
            'port': 9000\
        },\
        {\
            'name': 'Launch currently open script',\
            'type': 'php',\
            'request': 'launch',\
            'program': '${file}',\
            'cwd': '${fileDirname}',\
            'port': 9000\
        }\
    ]\
}\
" >> .vscode/launch.json


##Install Bless Hex Editor:
sudo apt-get install bless

##NOT STABLE, NEED TO TEST MORE WITH PYTHON/PIP
##Get python
#sudo apt-get install python 3
##Package Manager
#sudo apt-get install python-pip
##Required module
#pip install -U olefile
## Finally get the ole script
#wget "http://didierstevens.com/files/software/oledump_V0_0_3.zip"
#unzip "oledump_V0_0_3.zip"