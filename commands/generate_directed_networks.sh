INPUT_FILE="/home/eaman/research/bitcoin/processed-data/forums-posts-with-modified-symbol-or-name-unmodified-symbol-and-name-sorted-by-time.csv"
OUTPUT_DIR="/home/eaman/research/bitcoin/networks"

./analysis/generate_networks_timed.py $INPUT_FILE ${OUTPUT_DIR}/directed_90days/ -dn -hd 90

./analysis/generate_networks_timed.py $INPUT_FILE ${OUTPUT_DIR}/directed_60days/ -dn -hd 60

./analysis/generate_networks_timed.py $INPUT_FILE ${OUTPUT_DIR}/directed_30days/ -dn -hd 30

./analysis/generate_networks_timed.py $INPUT_FILE ${OUTPUT_DIR}/directed_7days/ -dn -hd 7 

./analysis/generate_networks.py $INPUT_FILE ${OUTPUT_DIR}/directed_unlimited -dn
