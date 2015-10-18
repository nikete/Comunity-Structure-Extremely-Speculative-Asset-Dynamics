# choices for time frame are unlimited, 7days, 30days, 60days and 90 days
TOP_NETWORKS_DIR="/home/eaman/research/bitcoin/networks"
TOP_USERS_DIR="/home/eaman/research/bitcoin/active-users-introducers"
TOP_OUTPUT_DIR="/home/eaman/research/bitcoin/metrics"
NUM_JOBS=3


for TIMEFRAME in "unlimited" "90days" "60days" "30days" "7days"
do
  NETWORKS_DIR="${TOP_NETWORKS_DIR}/directed_${TIMEFRAME}"
  OUTPUT_DIR="${TOP_OUTPUT_DIR}/directed_${TIMEFRAME}"
  rm -rf $OUTPUT_DIR
  mkdir $OUTPUT_DIR

  # Get metrics for users who initiated a new thread which mentioned both unmodified coin
  # name and symbol along with ANN] string, all in the subject of the thread for the first
  # time.
  USERS_DIR="${TOP_USERS_DIR}/${TIMEFRAME}/modified-symbol-and-name-in-subject-with-ANN-unmodified-symbol-and-name-in-subject-with-ANN"
  ./analysis/compute_network_metrics.py -s -dn -n $NUM_JOBS \
    -u ${USERS_DIR}/unmodified_coin_first_thread_post_introducers.csv \
    ${NETWORKS_DIR} \
    ${OUTPUT_DIR}/unmodified_symbol_and_name_in_subject_with_ANN_first_thread_post_introducers_metrics.csv


  # Get metrics for users who initiated a new thread which mentioned both unmodified coin
  # name and symbol in the subject of the thread for the first time.
  USERS_DIR="${TOP_USERS_DIR}/${TIMEFRAME}/modified-symbol-or-name-in-subject-unmodified-symbol-and-name-in-subject"
  ./analysis/compute_network_metrics.py -s -dn -n $NUM_JOBS \
    -u ${USERS_DIR}/unmodified_coin_first_thread_post_introducers.csv \
    ${NETWORKS_DIR} \
    ${OUTPUT_DIR}/unmodified_symbol_and_name_in_subject_first_thread_post_introducers_metrics.csv

  # Get metrics for users who initiated a new thread which mentioned both unmodified coin
  # name and symbol in the subject or content of the post for the first time.
  USERS_DIR="${TOP_USERS_DIR}/${TIMEFRAME}/modified-symbol-or-name-unmodified-symbol-and-name"
  ./analysis/compute_network_metrics.py -s -dn -n $NUM_JOBS \
    -u ${USERS_DIR}/unmodified_coin_first_thread_post_introducers.csv \
    ${NETWORKS_DIR} \
    ${OUTPUT_DIR}/unmodified_symbol_and_name_in_subject_or_content_first_thread_post_introducers_metrics.csv

  # Get metrics for users who mentioned both unmodified coin name and symbol in the subject
  # or content of any post for the first time.
  USERS_DIR="${TOP_USERS_DIR}/${TIMEFRAME}/modified-symbol-or-name-unmodified-symbol-and-name"
  ./analysis/compute_network_metrics.py -s -dn -n $NUM_JOBS \
    -u ${USERS_DIR}/unmodified_coin_first_introducers.csv \
    ${NETWORKS_DIR} \
    ${OUTPUT_DIR}/unmodified_symbol_and_name_in_subject_or_content_first_introducers_metrics.csv

  # Get metrics for users who mentioned modified coin name or symbol in the subject or
  # content of any post the most.
  USERS_DIR="${TOP_USERS_DIR}/${TIMEFRAME}/modified-symbol-or-name-unmodified-symbol-and-name"
  ./analysis/compute_network_metrics.py -s -dn -n $NUM_JOBS \
    -u ${USERS_DIR}/modified_coin_active_users.csv \
    ${NETWORKS_DIR} \
    ${OUTPUT_DIR}/modified_symbol_or_name_in_subject_or_content_active_users_metrics.csv
done

