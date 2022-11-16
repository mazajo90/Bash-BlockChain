#!/bin/bash
#Author=mazajo90
#Colors
green="\e[0:32m\033[1m"
red="\e[0:31m\033[1m"
yellow="\e[0:33m\033[1m"

echo -e "\n"
echo -e "${green} __        __ _   __  _  ____                   ${end}"
echo -e "${green} \ \      / /(_) / _|(_)|  _ \ __      __ _ __  ${end}"
echo -e "${green}  \ \ /\ / / | || |_ | || |_) |\ \ /\ / /| '_ \ ${end}"
echo -e "${green}   \ V  V /  | ||  _|| ||  __/  \ V  V / | | | |${end}"
echo -e "${green}    \_/\_/   |_||_|  |_||_|      \_/\_/  |_| |_|${end}"
echo -e "${green}                                                ${end}"
echo -e "\n"

function ctrl_c(){
	echo -e "\n${red}[-]Saliendo!!${end}"
	tput cnorm && exit 1

}

trap ctrl_c INT

function helpPanel(){
         echo -e "\n${green}[+] Uso de la herramienta: $0${end}"
         echo -e "\t${green}w) Colocar el nombre del SSID${end}"
}

function wifiPwn(){
	name="$1"
	pwd="$(sudo cat /etc/NetworkManager/system-connections/$name | grep -vE "connection|wifi|wifi-security|ipv4|ipv6|proxy|key" | grep -E "psk" | awk '{print $1}' | tr -d "psk|=")"

	if [ "$pwd" ]; then
		echo -e "${yellow}El password es:${end} ${green}$pwd${end}"
	else
		echo -e "${red}Ese SSID es incorrecto${end}" 2>/dev/null
	fi
}

declare -i parameter_counter=0


while getopts "w:h" arg; do
         case $arg in
                 w) name="$OPTARG"; let parameter_counter+=1;;
                 h);;
         esac
done

if [ $parameter_counter -eq 1 ]; then
         wifiPwn $name
else
         helpPanel
fi
