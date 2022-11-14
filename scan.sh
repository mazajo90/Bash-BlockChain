#!/bin/bash

#Author:mazajo90
#Colors
green="\e[0:32m\033[1m"
red="\e[0:31m\033[1m"

echo -e "\n"
echo -e "${green} ______                        _                        ${end}"
echo -e "${green}(_____ \              _       | |                       ${end}"
echo -e "${green} _____) )___    ____ | |_      \ \    ____  ____  ____  ${end}"
echo -e "${green}|  ____// _ \  / ___)|  _)      \ \  / ___)/ _  ||  _ \ ${end}"
echo -e "${green}| |    | |_| || |    | |__  _____) )( (___( ( | || | | |${end}"
echo -e "${green}|_|     \___/ |_|     \___)(______/  \____)\_||_||_| |_|${end}"
echo -e "${green}                        <Mazajo>                        ${end}"
echo -e "\n"

function crtl_c(){
    echo -e "\n${red}[!]Saliendo...\n${end}"
    tput cnorm; exit 1
}

#Control C para salir
trap crtl_c INT

#ip's
ip='192.168.1.1'

tput civis
for port in $(seq 1 65535); do
	timeout 1 bash -c "echo '' > /dev/tcp/$ip/$port" 2>/dev/null && echo -e "${green}[+] Puerto $port abierto en $ip${end}" &
done; wait
tput cnorm
