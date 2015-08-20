#!/usr/bin/env bash
shopt -s extglob

abspath_script="$(readlink -f -e "$0")"
script_absdir="$(dirname "$abspath_script")"
script_name="$(basename "$0" .sh)"

# Find perl scripts
tag_nucleosomes="${script_absdir}/perl/${script_name}.pl"

if [ $# -eq 0 ]
    then
        cat "$script_absdir/${script_name}_help.txt"
        exit 1
fi

TEMP=$(getopt -o hd:t: -l help,outdir:,threads: -n "$script_name.sh" -- "$@")

if [ $? -ne 0 ] 
then
  echo "Terminating..." >&2
  exit -1
fi

eval set -- "$TEMP"

# Defaults
outdir="$PWD"
threads=2

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
    -t|--threads)
      threads="$2"
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

# Start time
start_time="$(date +"%s%3N")"

# Inputs
peak_file="$1"
smooth_file="$2"

# Output
peak_file_basename="$(basename "$peak_file")"
peak_prefix="${peak_file_basename%%_peaks.*}"
peak_temp="${outdir}/${peak_prefix}"
smooth_file_basename="$(basename "$smooth_file")"
smooth_prefix="${smooth_file_basename%%.*}"
smooth_temp="${outdir}/${smooth_prefix}"
kernel_file="${peak_temp}_kernel.tmp"
outfile="${outdir}/${peak_prefix}_tags.cff.gz"

# Output directory
mkdir -p "$outdir"

# Export variables
export peak_file
export smooth_file
export peak_temp
export smooth_temp
export outfile
export tag_nucleosomes

# Get chromosomes
chromosomes="$(zcat "$peak_file" | cut -f 1 | uniq)"

# Generate a file for each chromosome for peak_file
echo "$chromosomes" | xargs -I {} --max-proc "$threads" bash -c \
    'zcat '$peak_file' | grep '{}[[:space:]]' | gzip > '${peak_temp}_{}.tmp.gz''

# Generate a file for each chromosome for smooth_file
echo "$chromosomes" | xargs -I {} --max-proc "$threads" bash -c \
    'zcat '$smooth_file' | grep '{}[[:space:]]' | gzip > '${smooth_temp}_{}.tmp.gz''

# Apply kernel and identify nucleosomes in all the chromosomes
echo "$chromosomes" | xargs -I {} --max-proc "$threads" bash -c \
    ''$tag_nucleosomes' '${peak_temp}_{}.tmp.gz' '${smooth_temp}_{}.tmp.gz' \
   | gzip > '${peak_temp}_{}.done.tmp.gz''

# Concatenate all chromosomes and filter
zcat ${peak_temp}_*.done.tmp.gz | gzip > "$outfile" 

# Remove temp file
rm -f ${peak_temp}*tmp* ${smooth_temp}*tmp*

# Time elapsed
end_time="$(date +"%s%3N")"
echo "Time elapsed: $(( $end_time - $start_time )) ms"

