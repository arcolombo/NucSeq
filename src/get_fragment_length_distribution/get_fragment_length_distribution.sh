#!/usr/bin/env bash
shopt -s extglob

abspath_script="$(readlink -f -e "$0")"
script_absdir="$(dirname "$abspath_script")"
script_name="$(basename "$0" .sh)"

if [ $# -eq 0 ]
    then
        cat "$script_absdir/${script_name}_help.txt"
        exit 1
fi

TEMP=$(getopt -o hd: -l help,outdir: -n "$script_name.sh" -- "$@")

if [ $? -ne 0 ] 
then
  echo "Terminating..." >&2
  exit -1
fi

eval set -- "$TEMP"

# Defaults
outdir="$PWD"

# Options
while true
do
  case "$1" in
    -h|--help)
      cat "$script_absdir"/${script_name}_help.txt
      exit
      ;;  
    -d|--outdir)
      outdir="$2"
      shift 2
      ;;  
    --) 
      shift
      break
      ;;  
    *)  
      echo "$script_name.sh:Internal error!"
      exit -1
      ;;  
  esac
done

# Inputs
input="$1"
extension="${input#*.}"
if [ "$extension" == "txt" ]
then
    txt_file="$input"
    txt_name="$(basename "$txt_file")"
    prefix="${txt_name%%.*}"
    # Outputs
    mkdir -p "$outdir"
    outfile_pdf="${outdir}/${prefix}.pdf"
    outfile_txt="$txt_file"
else
    bedgraph_file="$input"
    bedgraph_name="$(basename "$bedgraph_file")"
    prefix="${bedgraph_name%%.*}"
    # Outputs
    mkdir -p "$outdir"
    outfile_pdf="${outdir}/${prefix}.pdf"
    outfile_txt="${outdir}/${prefix}.txt"
fi


if [ ! "$extension" == "txt" ]
then
    # Get total number of reads
    total="$(zcat -f "$bedgraph_file" | awk 'BEGIN{FS="\t"}{total+=$4}END{print total}')"

    # Command
    zcat -f "$bedgraph_file" \
    | awk 'BEGIN{FS="\t";OFS="\t"}{print $3-$2,$4}' \
    | sort -k 1,1n \
    | groupBy -g 1 -c 2 -o sum \
    | awk -v total="$total" 'BEGIN{FS="\t";OFS="\t";i=1}{if(i<=500){while(i!=$1){print i,0;i++}print i,$2/total;i++}}' > "$outfile_txt"
fi

# Plot the distribution
Rscript "${script_absdir}/R/${script_name}.R" "$outfile_txt" "$outfile_pdf"  &>/dev/null
rm -f "Rplots.pdf"
