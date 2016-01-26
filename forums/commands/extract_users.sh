FORUM_INPUT_DIR="/home/eaman/research/bitcoin/nikete_tmp/forum-data"
COIN_INPUT_DIR="/home/eaman/research/bitcoin/nikete_tmp/coin-data"
PARENT_OUTPUT_DIR="/home/eaman/research/bitcoin/nikete_tmp/active-users-introducers"

# users extracted based on unlimited
for DAYS in -1
do
  TOP_OUTPUT_DIR="${PARENT_OUTPUT_DIR}/${DAYS}days"
  if [ $DAYS == "-1" ]
  then
    TOP_OUTPUT_DIR="${PARENT_OUTPUT_DIR}/unlimited"
  fi

  INPUT_FILE="${FORUM_INPUT_DIR}/unmodified-symbol-or-name-in-subject-content----unmodified-symbol-and-name-in-subject-content-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/unmodified-symbol-or-name-in-subject-content----unmodified-symbol-and-name-in-subject-content"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ../analysis/extract_coin_users.py -u 3 -nau 3 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/unmodified-symbol-or-name-in-subject----unmodified-symbol-and-name-in-subject-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/unmodified-symbol-or-name-in-subject----unmodified-symbol-and-name-in-subject"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ../analysis/extract_coin_users.py -u 3 -nau 3 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-and-name-in-subject-with-ANN-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-and-name-in-subject-with-ANN"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ../analysis/extract_coin_users.py -u 3 -nau 3 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/unmodified-symbol-or-name-in-subject----unmodified-symbol-or-name-in-subject-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/unmodified-symbol-or-name-in-subject----unmodified-symbol-or-name-in-subject"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ../analysis/extract_coin_users.py -u 3 -nau 3 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv


  INPUT_FILE="${FORUM_INPUT_DIR}/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-or-name-in-subject-with-ANN-sorted-by-time.csv"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-or-name-in-subject-with-ANN"
  rm -rf $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR
  ../analysis/extract_coin_users.py -u 3 -nau 3 -hd $DAYS \
    $INPUT_FILE \
    $OUTPUT_DIR \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv \
    ${COIN_INPUT_DIR}/all-coins-with-earliest-trade-date-unmodified.csv
done

