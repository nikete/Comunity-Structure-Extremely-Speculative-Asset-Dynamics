ANALYSIS_DIR="/home/eaman/research/bitcoin/analysis"
GENERATE_NETWORKS_TIMED="${ANALYSIS_DIR}/generate_networks_timed.py"
GENERATE_NETWORKS="${ANALYSIS_DIR}/generate_networks.py"
EXTRACT_COIN_USERS="${ANALYSIS_DIR}/extract_coin_users.py"
COMPUTE_METRICS="${ANALYSIS_DIR}/compute_network_metrics.py"
TESTDATA_DIR="${ANALYSIS_DIR}/testdata"
SAMPLE1_MENTIONS="${TESTDATA_DIR}/sample_coin_mention_history1.csv"
SAMPLE1_DATES="${TESTDATA_DIR}/sample_coin_earliest_date1.csv"
SAMPLE2_MENTIONS="${TESTDATA_DIR}/sample_coin_mention_history2.csv"
SAMPLE2_DATES="${TESTDATA_DIR}/sample_coin_earliest_date2.csv"
TMP_OUTPUT="${ANALYSIS_DIR}/tmp_output_to_delete"
TMP_USERS="${TMP_OUTPUT}/modified_coin_active_users.csv"
TMP_METRICS1="${ANALYSIS_DIR}/tmp_metrics1_to_delete"
TMP_METRICS2="${ANALYSIS_DIR}/tmp_metrics2_to_delete"

NUM_URLS=2
rewrite_test_data=false
if [ "$rewrite_test_data" = true ] ; then
  # CREATE TIMED INPUTS
  OUTPUT=${TESTDATA_DIR}/fourdays_sample1_directed_nau1_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/fourdays_sample1_directed_nau1_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/fourdays_sample1_directed_nau1_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS_TIMED $SAMPLE1_MENTIONS $OUTPUT -hd 4 -dn
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -hd 4 -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS -dn > /dev/null

  OUTPUT=${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS_TIMED $SAMPLE1_MENTIONS $OUTPUT -hd 4
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -hd 4 -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS > /dev/null
  
  OUTPUT=${TESTDATA_DIR}/twodays_sample2_directed_nau1_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/twodays_sample2_directed_nau1_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/twodays_sample2_directed_nau1_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS_TIMED $SAMPLE2_MENTIONS $OUTPUT -hd 2 -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -hd 2 -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS -dn > /dev/null

  OUTPUT=${TESTDATA_DIR}/twodays_sample2_undirected_nau2_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/twodays_sample2_undirected_nau2_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/twodays_sample2_undirected_nau2_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS_TIMED $SAMPLE2_MENTIONS $OUTPUT -hd 2
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -hd 2 -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS > /dev/null



  # TEST UNTIMED INPUTS
  OUTPUT=${TESTDATA_DIR}/untimed_sample1_undirected_nau3_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/untimed_sample1_undirected_nau3_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/untimed_sample1_undirected_nau3_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS $SAMPLE1_MENTIONS $OUTPUT
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -nau 3 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS  > /dev/null

  OUTPUT=${TESTDATA_DIR}/untimed_sample1_undirected_nau1_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/untimed_sample1_undirected_nau1_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/untimed_sample1_undirected_nau1_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS $SAMPLE1_MENTIONS $OUTPUT
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS > /dev/null

  OUTPUT=${TESTDATA_DIR}/untimed_sample2_directed_nau2_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/untimed_sample2_directed_nau2_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/untimed_sample2_directed_nau2_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS $SAMPLE2_MENTIONS $OUTPUT -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS -dn > /dev/null

  OUTPUT=${TESTDATA_DIR}/untimed_sample2_directed_nau4_output
  USERS=${OUTPUT}/modified_coin_active_users.csv
  METRICS1=${TESTDATA_DIR}/untimed_sample2_directed_nau4_by_date_metrics.csv
  METRICS2=${TESTDATA_DIR}/untimed_sample2_directed_nau4_metrics.csv
  rm $OUTPUT -rf
  rm $METRICS1
  rm $METRICS2
  $GENERATE_NETWORKS $SAMPLE2_MENTIONS $OUTPUT -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -nau 4 -u $NUM_URLS
  $COMPUTE_METRICS $OUTPUT $METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $OUTPUT $METRICS2 -u $USERS -dn > /dev/null

else
  # TEST TIMED INPUTS
  $GENERATE_NETWORKS_TIMED $SAMPLE1_MENTIONS $TMP_OUTPUT -hd 4 -dn
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $TMP_OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -hd 4 -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS -dn > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/fourdays_sample1_directed_nau1_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/fourdays_sample1_directed_nau1_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/fourdays_sample1_directed_nau1_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS_TIMED $SAMPLE1_MENTIONS $TMP_OUTPUT -hd 4
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $TMP_OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -hd 4 -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/fourdays_sample1_undirected_nau2_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS_TIMED $SAMPLE2_MENTIONS $TMP_OUTPUT -hd 2 -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $TMP_OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -hd 2 -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS -dn > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/twodays_sample2_directed_nau1_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/twodays_sample2_directed_nau1_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/twodays_sample2_directed_nau1_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS_TIMED $SAMPLE2_MENTIONS $TMP_OUTPUT -hd 2
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $TMP_OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -hd 2 -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/twodays_sample2_undirected_nau2_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/twodays_sample2_undirected_nau2_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/twodays_sample2_undirected_nau2_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2



  # TEST UNTIMED INPUTS
  $GENERATE_NETWORKS $SAMPLE1_MENTIONS $TMP_OUTPUT
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $TMP_OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -nau 3 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/untimed_sample1_undirected_nau3_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/untimed_sample1_undirected_nau3_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/untimed_sample1_undirected_nau3_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS $SAMPLE1_MENTIONS $TMP_OUTPUT
  $EXTRACT_COIN_USERS $SAMPLE1_MENTIONS $TMP_OUTPUT $SAMPLE1_DATES $SAMPLE1_DATES -nau 1 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/untimed_sample1_undirected_nau1_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/untimed_sample1_undirected_nau1_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/untimed_sample1_undirected_nau1_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS $SAMPLE2_MENTIONS $TMP_OUTPUT -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $TMP_OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -nau 2 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS -dn > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/untimed_sample2_directed_nau2_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/untimed_sample2_directed_nau2_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/untimed_sample2_directed_nau2_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2

  $GENERATE_NETWORKS $SAMPLE2_MENTIONS $TMP_OUTPUT -dn
  $EXTRACT_COIN_USERS $SAMPLE2_MENTIONS $TMP_OUTPUT $SAMPLE2_DATES $SAMPLE2_DATES -nau 4 -u $NUM_URLS
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS1 -dn > /dev/null
  $COMPUTE_METRICS $TMP_OUTPUT $TMP_METRICS2 -u $TMP_USERS -dn > /dev/null
  diff -bur $TMP_OUTPUT ${TESTDATA_DIR}/untimed_sample2_directed_nau4_output
  diff $TMP_METRICS1 ${TESTDATA_DIR}/untimed_sample2_directed_nau4_by_date_metrics.csv
  diff $TMP_METRICS2 ${TESTDATA_DIR}/untimed_sample2_directed_nau4_metrics.csv
  rm $TMP_OUTPUT -rf
  rm $TMP_METRICS1
  rm $TMP_METRICS2
fi    # end if recreate_test_data else
