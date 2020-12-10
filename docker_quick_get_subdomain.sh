#!/bin/sh

# TARGET=$1
WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
TOOLS_PATH="/root/go/bin"
GOPATH="/root/go/bin"
DICTIONARY="/app/dictionary"
TOOLS_SCAN="/root/hackingtools"

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"


checkArgs()
{
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}[+] Usage:${RESET} $0 -d <domain>\n"
        echo -e "${RED}[+] Usage:${RESET} $0 -d <domain> check\n"
        exit 1
    fi
}

runBanner()
{
    name=$1
    echo -e "${RED}\n[+] Running $name...${RESET}"
}


function setupDir()
{
    echo -e "${GREEN}--==[ Setting things up ]==--${RESET}"
    mkdir -p Domains 
    rm -rf $RESULTS_PATH
    echo -e "${RED}\n[+] Creating results directories...${RESET}"    
    mkdir -p $RESULTS_PATH
    echo -e "${BLUE}[*] $RESULTS_PATH${RESET}"  
}

function get_subdomains()
{
    $TOOLS_PATH/subfinder -d $TARGET -o $RESULTS_PATH/subfinder.$TARGET.txt 
    sleep 2
    $TOOLS_PATH/assetfinder --subs-only $TARGET >> $RESULTS_PATH/assetfinder.$TARGET.txt
    sleep 2
    $TOOLS_PATH/findomain -t $TARGET -u $RESULTS_PATH/fd.$TARGET.txt
    sleep 2
    aiodnsbrute -w /app/dictionary/subs-100000.txt  -r /app/dictionary/google.txt  -t 3000 -f $RESULTS_PATH/aiodnsbrute.$TARGET.csv -o csv $TARGET
    sleep 2
    cat $RESULTS_PATH/aiodnsbrute.$TARGET.csv| awk -F "," '{print $1}' > $RESULTS_PATH/aiodnsbrute.$TARGET.txt
    cat $RESULTS_PATH/*.txt|sort |uniq > $RESULTS_PATH/subdomains.$TARGET.txt
}


function get_domains()
{
        echo -e "${GREEN}\n--==[ Running ScanPort ]==--${RESET}"
        cat $RESULTS_PATH/subdomains.$TARGET.txt|$TOOLS_PATH/naabu -ports 80,443,8080,8443,7071,10250,8008,8081 -silent -rate 1000 |$TOOLS_PATH/httpx -silent -no-color -o $RESULTS_PATH/urls-total.$TARGET.txt
        
        echo -e "${GREEN}\n--==[ Found URL: ]==--${RESET}"
        cat $RESULTS_PATH/urls-total.$TARGET.txt
        echo -e "${GREEN}\n--==[ Done ]==--${RESET}"
}


function enumIP()
{
    go get -u github.com/dwisiswant0/cf-check
    apk add --update linux-headers
    apk add libpcap-dev libpcap


    /app/tools/massdns/bin/massdns -t A -o S -s 5000 -w $RESULTS_PATH/massdns.out -r /app/dictionary/google.txt --root $RESULTS_PATH/subdomains.$TARGET.txt
    sleep 1
    cat $RESULTS_PATH/massdns.out|awk '{print $3}' |sort -u |uniq| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $RESULTS_PATH/get-ip.txt
    sleep 1
    /app/tools/masscan/bin/masscan -iL $RESULTS_PATH/get-ip.txt -p 1-65535 --max-rate 5000 -sS -Pn --open -oG $RESULTS_PATH/masscan.gnmap
    sleep 5
    cat $RESULTS_PATH/masscan.gnmap| grep Host | awk '{print $4,$7}' | sed 's@/.*@@' | sort -t' ' -n -k2 | awk -F' ' -v OFS=' ' '{x=$1;$1="";a[x]=a[x]","$0}END{for(x in a) print x,a[x]}' | sed 's/, /,/g' | sed 's/ ,/ /' | sort -V -k1 | cut -d " " -f1 > $RESULTS_PATH/HOSTS
    sleep 1
    cat $RESULTS_PATH/masscan.gnmap| grep Host | awk '{print $4,$7}' | sed 's@/.*@@' | sort -t' ' -n -k2 | awk -F' ' -v OFS=' ' '{x=$1;$1="";a[x]=a[x]","$0}END{for(x in a) print x,a[x]}' | sed 's/, /,/g' | sed 's/ ,/ /' | sort -V -k1 | cut -d " " -f2  > $RESULTS_PATH/OPEN_PORTS

    awk '{if(length($0) > 100){$0="80,443,8080,8888,9999,8808,7071,8443,4443,6443" } ; print $0}' $RESULTS_PATH/OPEN_PORTS > $RESULTS_PATH/PORTS

    paste -d "\t" $RESULTS_PATH/HOSTS $RESULTS_PATH/OPEN_PORTS > $RESULTS_PATH/MAP_HOSTS_PORTS

    python3 /app/tools/parseMasscanToHost.py $RESULTS_PATH/MAP_HOSTS_PORTS >> $RESULTS_PATH/map-hosts.txt

    cat $RESULTS_PATH/map-hosts.txt| httpx -timeout 20 -threads 30 -silent -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36" -follow-redirects -o $RESULTS_PATH/ip-alive.txt
    sleep 5
    cat $RESULTS_PATH/ip-alive.txt |sort |uniq >>  $RESULTS_PATH/urls-total.$TARGET.txt
}



label()
{

echo "
 _ __ ___  ___ ___  _ __  
| '__/ _ \/ __/ _ \| '_ \ 
| | |  __/ (_| (_) | | | |
|_|  \___|\___\___/|_| |_|
                          
"

}

function printHelp()
{
        echo -e "
Usage:

-d|--domain                            Domain target
-f|--upload_file                        Absolute location of local file to upload on the target.
-k|--check                              Check security bug on subdomains list
-v|--verbose                            Also prints curl command which is going to be executed
-h|--help                               Print Help menu


Example:
./recon.sh -d vng.com.vn --check
"
}

while [[ "$#" -gt 0 ]]
do
key="$1"
check="false"

case "$key" in
    -d|--domain)
            domain="$2"
            shift
            shift # past argument
            ;;
    -k|--check)
            check="true"
            shift
            shift
            ;;
    -v|--verbose)
            verbose="true"
            shift
            ;;
    -h|--help)
            printHelp
            exit
            shift
            ;;
    *)   
            echo [-] Enter valid options
            exit
            ;;
esac
done

label

TARGET=$domain
RESULTS_PATH="$WORKING_DIR/Domains/$TARGET"

setupDir
sleep 1
[[ ! -s "$domain" ]] && [[ "$check" == "false" ]] && TARGET=$domain && get_subdomains $TARGET && get_domains && enumIP
[[ ! -s "$domain" ]] && [[ "$check" == "true" ]] && TARGET=$domain && get_domains $TARGET && /root/tools/gotools/scan-vuln.sh $TARGET
sleep 1
# get_domains
