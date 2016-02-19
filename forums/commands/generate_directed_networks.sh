INPUT_FILE="./forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-or-name-in-subject-sorted-by-time.csv"
OUTPUT_DIR="./networks"

./forums/analysis/generate_networks.py $INPUT_FILE ${OUTPUT_DIR}/directed_unlimited -dn
