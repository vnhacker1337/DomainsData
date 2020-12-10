#!/bin/sh



TARGET=$1
WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
TOOLS_PATH="/root/go/bin"
SCREENSHOT="$WORKING_DIR/SCREENSHOT"

checkArgs()
{
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}[+] Usage:${RESET} $0 <domain>\n"
        echo -e "${RED}[+] Usage:${RESET} $0 <domain> full\n"
        exit 1
    fi
}

runBanner()
{
    name=$1
    echo -e "${RED}\n[+] Running $name...${RESET}"
}


setupDir()
{
    echo -e "${GREEN}--==[ Setting things up ]==--${RESET}"
    echo -e "${RED}\n[+] Creating results directories...${RESET}"    
    mkdir -p $SCREENSHOT
    echo -e "${BLUE}[*] $RESULTS_PATH${RESET}"  
}

screenshot()
{
  
  cat $1| $TOOLS_PATH/aquatone -screenshot-timeout 60000 -http-timeout 60000 -threads 10 -out $SCREENSHOT/$2
}

checkArgs $1
runBanner
setupDir
screenshot $1 $2

