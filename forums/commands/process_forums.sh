# Sort posts by time and get label posts by
# 1- unmodified coin name OR symbol mention in concatenation of subject and content
# 2- unmodified coin name AND symbol mention in concatenation of subject and content
../process-data/add_coin_mentions_sort_by_time.py -mms sc,nORs -ums sc,nANDs \
  ../crawled-data/bitcointalk/bitcoin-data.csv \
  ../crawled-data/bitcointalk/altcoin-data.csv \
  ../crawled-data/bitcointalk/announcements-data.csv \
  ../crawled-data/bitcointalk/marketplace-data.csv \
  ../crawled-data/bitcointalk/mining-data.csv \
  ./coin-data/coin-names-modified.csv ./coin-data/coin-names-unmodified.csv \
  ./forum-data/unmodified-symbol-or-name-in-subject-content----unmodified-symbol-and-name-in-subject-content-sorted-by-time.csv

# Sort posts by time and get label posts by
# 1- unmodified coin name OR symbol mention in subject only
# 2- unmodified coin name AND symbol mention in subject only
#../process-data/add_coin_mentions_sort_by_time.py -mms s,nORs -ums s,nANDs \
#  ../crawled-data/bitcointalk/bitcoin-data.csv \
#  ../crawled-data/bitcointalk/altcoin-data.csv \
#  ../crawled-data/bitcointalk/announcements-data.csv \
#  ../crawled-data/bitcointalk/marketplace-data.csv \
#  ../crawled-data/bitcointalk/mining-data.csv \
#  ./coin-data/coin-names-modified.csv ./coin-data/coin-names-unmodified.csv \
#  ./forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-and-name-in-subject-sorted-by-time.csv

# Sort posts by time and get label posts by
# 1- unmodified coin name OR symbol mention in subject only, also containing ANN string
# 2- unmodified coin name AND symbol mention in subject only, also containing ANN string
#../process-data/add_coin_mentions_sort_by_time.py -mms s,nORs -ums s,nANDs -es "ANN" \
#  ../crawled-data/bitcointalk/bitcoin-data.csv \
#  ../crawled-data/bitcointalk/altcoin-data.csv \
#  ../crawled-data/bitcointalk/announcements-data.csv \
#  ../crawled-data/bitcointalk/marketplace-data.csv \
#  ../crawled-data/bitcointalk/mining-data.csv \
#  ./coin-data/coin-names-modified.csv ./coin-data/coin-names-unmodified.csv \
#  ./forum-data/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-and-name-in-subject-with-ANN-sorted-by-time.csv

# Sort posts by time and get label posts by
# 1- unmodified coin name OR symbol mention in subject only
# 2- unmodified coin name OR symbol mention in subject only
#../process-data/add_coin_mentions_sort_by_time.py -mms s,nORs -ums s,nORs \
#  ../crawled-data/bitcointalk/bitcoin-data.csv \
#  ../crawled-data/bitcointalk/altcoin-data.csv \
#  ../crawled-data/bitcointalk/announcements-data.csv \
#  ../crawled-data/bitcointalk/marketplace-data.csv \
#  ../crawled-data/bitcointalk/mining-data.csv \
#  ./coin-data/coin-names-modified.csv ./coin-data/coin-names-unmodified.csv \
#  ./forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-or-name-in-subject-sorted-by-time.csv

# Sort posts by time and get label posts by
# 1- unmodified coin name OR symbol mention in subject only, also containing ANN string
# 2- unmodified coin name OR symbol mention in subject only, also containing ANN string
#../process-data/add_coin_mentions_sort_by_time.py -mms s,nORs -ums s,nORs -es "ANN" \
#  ../crawled-data/bitcointalk/bitcoin-data.csv \
#  ../crawled-data/bitcointalk/altcoin-data.csv \
#  ../crawled-data/bitcointalk/announcements-data.csv \
#  ../crawled-data/bitcointalk/marketplace-data.csv \
#  ../crawled-data/bitcointalk/mining-data.csv \
#  ./coin-data/coin-names-modified.csv ./coin-data/coin-names-unmodified.csv \
#  ./forum-data/unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-or-name-in-subject-with-ANN-sorted-by-time.csv
