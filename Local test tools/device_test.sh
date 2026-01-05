#!/bin/ksh
if [ $# -ne 1 ] ; then
   echo "ERROR: invalid use. Specify file name to submit as parameter."
   exit 1
fi

if [ ! -f "$1" ] ; then
   echo "ERROR: Input file '$1' not found."
   exit 1
fi

echo "Sending request to mySHiT"
#curl -d "@$1" "http://www.shitt.no/mySHiT/device?userName=persolberg@hotmail.com&password=Vertex70"
curl -d "@$1" "http://www.shitt.no/mySHiT/device"
echo ""
