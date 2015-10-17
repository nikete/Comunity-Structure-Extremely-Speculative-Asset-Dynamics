import pandas as pd

fname = '/home/octavio/Programación/Dropbox/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/data/directed_unlimited/unmodified_symbol_and_name_in_subject_with_ANN_first_thread_post_introducers_metrics.csv'
data = pd.read_csv( fname, 
   index_col='coin').join(pd.read_csv(
       'data/coinsunique.csv',index_col='coin')).join(pd.read_csv(
       'data/prices.csv',index_col='symbol',skipinitialspace=True))

print(len(data))
data.to_csv('test.csv')
