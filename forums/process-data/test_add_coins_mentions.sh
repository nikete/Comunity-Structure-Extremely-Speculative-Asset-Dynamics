PROCESS_DIR="/home/eaman/research/bitcoin/process-data"
COIN_DATA_DIR="/home/eaman/research/bitcoin/coin-data"
ADD_COIN_MENTIONS="${PROCESS_DIR}/add_coin_mentions_sort_by_time.py"
TESTDATA_DIR="${PROCESS_DIR}/testdata"
TMP_DIR="${PROCESS_DIR}/tmp_output_to_delete"
TMP_OUTPUT1="${TMP_DIR}/tmp_sorted_mentions_to_delete1"
TMP_OUTPUT2="${TMP_DIR}/tmp_sorted_mentions_to_delete2"
TMP_OUTPUT3="${TMP_DIR}/tmp_sorted_mentions_to_delete3"

GOLDEN1="${TESTDATA_DIR}/forum_posts.mms_sc,nORs.ums_sc,nANDs.golden"
GOLDEN2="${TESTDATA_DIR}/forum_posts.mms_s,nORs.ums_s,nANDs.golden"
GOLDEN3="${TESTDATA_DIR}/forum_posts.mms_s,nORs.ums_s,nORs.es_ANN.golden"

rewrite_test_data=false
if [ "$rewrite_test_data" = true ] ; then
  # Regenerate the golden data
  echo -e "\nGenerating modified coin name OR symbol and unmodified name AND symbol in subject and content"
  $ADD_COIN_MENTIONS -mms sc,nORs -ums sc,nANDs \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $GOLDEN1 &> /dev/null

  echo -e "\nGenerating modified coin name OR symbol and unmodified name AND symbol in subject only"
  $ADD_COIN_MENTIONS -mms s,nORs -ums s,nANDs \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $GOLDEN2 &> /dev/null
  
  echo -e "\nGenerating modified coin name OR symbol and unmodified name OR symbol with ANN string in subject only"
  $ADD_COIN_MENTIONS -mms s,nORs -ums s,nORs -es "ANN" \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $GOLDEN3 &> /dev/null
else
  # Do the actual testin
  mkdir $TMP_DIR

  echo -e "\nTesting with modified coin name OR symbol and unmodified name AND symbol in subject and content"
  $ADD_COIN_MENTIONS -mms sc,nORs -ums sc,nANDs \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $TMP_OUTPUT1 &> /dev/null
  if [ "$(diff $TMP_OUTPUT1 $GOLDEN1)" != "" ]; then
    echo "Failed!"
  else
    echo "Passed!"
  fi

  echo -e "\nTesting with modified coin name OR symbol and unmodified name AND symbol in subject only"
  $ADD_COIN_MENTIONS -mms s,nORs -ums s,nANDs \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $TMP_OUTPUT2 &> /dev/null
  if [ "$(diff $TMP_OUTPUT2 $GOLDEN2)" != "" ]; then
    echo "Failed!"
  else
    echo "Passed!"
  fi

  echo -e "\nTesting with modified coin name OR symbol and unmodified name OR symbol with ANN string in subject only"
  $ADD_COIN_MENTIONS -mms s,nORs -ums s,nORs -es "ANN" \
    "$TESTDATA_DIR/bitcoin-data.csv" \
    "$TESTDATA_DIR/altcoin-data.csv" \
    "$TESTDATA_DIR/announcements-data.csv" \
    "$TESTDATA_DIR/marketplace-data.csv" \
    "$TESTDATA_DIR/mining-data.csv" \
    "$COIN_DATA_DIR/coin-names-modified.csv" \
    "$COIN_DATA_DIR/coin-names-unmodified.csv" \
    $TMP_OUTPUT3 &> /dev/null
  if [ "$(diff $TMP_OUTPUT3 $GOLDEN3)" != "" ]; then
    echo "Failed!"
  else
    echo "Passed!"
  fi

  rm -rf $TMP_DIR
fi
