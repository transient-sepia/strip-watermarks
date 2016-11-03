#!/usr/bin/env bash
#
# strip-chan
# version 1.0
# 
# / neat. /
#

# paths to required tools
QPDF="/opt/watermark-removal/qpdf/bin/qpdf"
PDFTK="/usr/bin/pdftk"
EXIFTOOL="/usr/local/bin/exiftool"

# usage
USAGE="\n\tstrip_watermarks - remove watermarks from guides.\n\n \
\tstrip_watermarks.sh [-h] -i <INPUT_FILE>\n\n \
\t-h - print this message.\n \
\t-i - input filename.\n"

# trap ctrl-c
trap "ctrl_c; exit" INT

function ctrl_c () {
  echo "** Trapped CTRL-C"
}

while getopts 'hi:' opt
do
  case $opt in
    h) echo -e "${USAGE}"
       exit 1
       ;;
    i) IFILE=${OPTARG}
       ;;
    :) echo "option -$opt requires an argument"
       ;;
    *) echo -e "${USAGE}"
       exit 2
       ;;
  esac
done

# functions
function check () {
  if [ $? != 0 ]; then
    echo "${ERRMSG}"
    exit 1
  fi
}

function clean_pdf () {
  TEMPF="d t u"
  FILE=$1
  FILE="${FILE%%.*}"
  echo "Removing watermark(s) from $1..."
  if [ -e "$1" ]; then
    ERRMSG="Couldn't decrypt the input file."
    ${QPDF} --decrypt "${FILE}.pdf" "${FILE}_d.pdf"
    check
    ERRMSG="Couldn't decompress the input file."
    ${PDFTK} "${FILE}_d.pdf" output "${FILE}_u.pdf" uncompress
    check
    ERRMSG="Couldn't remove pdf metadata."
    ${EXIFTOOL} -q -q -overwrite_original -all:all= "${FILE}_u.pdf"
    check
    ERRMSG="Couldn't process the input file."
    sed -e "s/\/Xi[0-9]* Do Q//g" < "${FILE}_u.pdf" > "${FILE}_t.pdf"
    check
    ${PDFTK} "${FILE}_t.pdf" output "${FILE}_nw.pdf" compress
    if [ $? = 0 ]; then
      echo "Done! Saved to \"${FILE}_nw.pdf\""
      ERRMSG="Couldn't clean temporary files."
      for i in ${TEMPF}; do
        if [ -e "${FILE}_${i}.pdf" ]; then
          rm -f "${FILE}_${i}.pdf"
          check
        fi
      done
    else
      echo "Couldn't produce the output file."
    fi
  else
    echo "File not found!"
  fi
}

# check parameter
if [ -z ${IFILE} ]; then
  printf "<INPUT_FILE> parameter is mandatory. Use -h.\n"
  exit 1
fi

# main
clean_pdf ${IFILE}

# exit
exit 0
