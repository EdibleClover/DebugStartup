#!/usr/bin/

## Bash script to set up PHP debugging environment and Nencessary tools:::
##To do, Work eval hook into this somehow, I think itd be easiest to package docker and run it off that since its a dev build of PHP which is annoying to work with.
##Fix permissions issues


##sudo -u username command   Run as original user

#Skip confirmations with yes command

if [ $# -ge 1 ]
then
    while true; do echo "$1"; done
else
    while true; do echo y; done
fi




#Install PHP, DEFAULT TO 7.1
	sudo apt-get install software-properties-common
	sudo add-apt-repository ppa:ondrej/php
	echo -e "\n\ninstalling php Version 7.1\n\n";
	sudo apt install php7.1
	echo -e "For more information about installing additional version of php visit:\n https://www.tecmint.com/install-different-php-versions-in-ubuntu/";
	php -v
	
##INSTALL X DEBUG AND MODIFY PHP INI
	echo -e "\n\n:::installing xDebug:::\n\n"
		sudo apt-get install php-xdebug
	echo -e 'checking INI\n'
		iniFile=`php -r 'echo php_ini_loaded_file();'`
	echo -e "modifying PHP ini @ \\n ${iniFile}"
	
	echo -e "[XDebug]\n\
		xdebug.remote_enable = 1\n\
		xdebug.remote_autostart = 1\n" | sudo tee -a ${inifile} >/dev/null  


		
##Check and make sure xDebug is listed as a PHP module
	xDebugCheck=`php -m | grep 'xdebug'`
	if [ -z '$xDebugCheck' ]
	then
			echo -e "Xdebug installation failed\n"
	else
			echo -e "Xdebug installation succeeded!\n"
	fi
	
## Make sure that ini file was written to
iniCheck = `grep 'xdebug' ${inifile}`
	if [ -z '$iniCheck' ]
	then
			echo -e "\n\nini file successfully modified!\n\n"
	else
			echo -e "\n\nini modification failed, you may need to manually modify your PHP ini file @ ${inifile}\n\n"
	fi


echo -e "Installing Additional tools\n list:\n https://github.com/prettier/plugin-php\n\n"
##Lets setup a directory with all of our tools
mkdir ~/Desktop/phpDebug

cd ~/Desktop/phpDebug


## install Composer, 
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

echo -e '\n\nComposer succesfully installed in Desktop/phpDebug\n\n'


##Install additional modules
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



## Install Visual Studio Code
sudo snap install code --classic

##Installe debugger plugin
code --install-extension felixfbecker.php-debug

## Create a launch JSON for debug plugin
##Need to escape text

mkdir ~/Desktop/phpDebug/.vscode & touch ~/Desktop/phpDebug/phpDebug.code-workspace

echo -e "\
{\n\
    \"version\": \"0.2.0\",\n\
    \"configurations\": [\n\
        {\n\
            \"name\": \"Listen for XDebug\",\n\
            \"type\": \"php\",\n\
            \"request\": \"launch\",\n\
            \"port\": 9000\n\
        },\n\
        {\n\
            \"name\": \"Launch currently open script\",\n\
            \"type\": \"php\",\n\
            \"request\": \"launch\",\n\
            \"program\": \"\${file}\",\n\
            \"cwd\": \"\${fileDirname}\",\n\
            \"port\": 9000\n\
        }\n\
    ]\n\
}\n\
" >> .vscode/launch.json

echo -e "\
{\n\
	\"folders\": [\n\
		{\n\
			\"path\": \".\"\n\
		}\n\
	]\n\
}\n\
" >> ./phpDebug.code-workspace

##Need to setup workspace folder##

