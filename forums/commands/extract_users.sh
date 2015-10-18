FORUM_INPUT_DIR="/home/eaman/research/bitcoin/forum-data"
COIN_INPUT_DIR="/home/eaman/research/bitcoin/coin-data"
PARENT_OUTPUT_DIR="/home/eaman/research/bitcoin/active-users-introducers"

# users extracted based on unlimited, 90days, 60days, 30days and 7days time frame
for DAYS in -1 90 60 30 7 
do
  TOP_OUTPUT_DIR="${PARENT_OUTPUT_DIR}/${DAYS}days"
  if [ $DAYS == "-1" ]
  then
    TOP_OUTPUT_DIR="${PARENT_OUTPUT_DIR}/unlimited"
  fi

  INPUT_FILE="${FORUM_INPUT_DIR}/forums-posts-with-modified-symbol-or-name-unmodified-symbol-and-name-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/modified-symbol-or-name-unmodified-symbol-and-name"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ./analysis/extract_coin_users.py -u 5 -nau 5 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-modified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv

  INPUT_FILE="${FORUM_INPUT_DIR}/forums-posts-with-modified-symbol-or-name-in-content-unmodified-symbol-and-name-in-content-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/modified-symbol-or-name-in-content-unmodified-symbol-and-name-in-content"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ./analysis/extract_coin_users.py -u 5 -nau 5 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-modified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/forums-posts-with-modified-symbol-or-name-in-subject-unmodified-symbol-and-name-in-subject-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/modified-symbol-or-name-in-subject-unmodified-symbol-and-name-in-subject"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ./analysis/extract_coin_users.py -u 5 -nau 5 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-modified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/forums-posts-with-modified-symbol-and-name-in-subject-with-ANN-unmodified-symbol-and-name-in-subject-with-ANN-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/modified-symbol-and-name-in-subject-with-ANN-unmodified-symbol-and-name-in-subject-with-ANN"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ./analysis/extract_coin_users.py -u 5 -nau 5 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-modified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv
done

