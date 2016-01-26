INPUT_FILE="/home/eaman/research/bitcoin/nikete_tmp/forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-or-name-in-subject-sorted-by-time.csv"
OUTPUT_DIR="/home/eaman/research/bitcoin/nikete_tmp/networks"

../analysis/generate_networks.py $INPUT_FILE ${OUTPUT_DIR}/directed_unlimited -dn
