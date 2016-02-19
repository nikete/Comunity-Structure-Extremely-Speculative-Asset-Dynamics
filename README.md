# Comunity-Structure-Extremely-Speculative-Asset-Dynamics
Can features based on the network structure around a particular cryptocurrency beforeit trades, predict the severity and magnitude of the subsequent bubbles?

latest PDF: https://www.sharelatex.com/github/repos/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics

[![PDF Status](https://www.sharelatex.com/github/repos/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/builds/latest/badge.svg)](https://www.sharelatex.com/github/repos/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/builds/latest/output.pdf)

## Data Description:
1. **Forum data:** The processed forum data can be found [here](https://www.dropbox.com/sh/grxbcuyo4cquyow/AABgnyGD0EtpJwrzfkgJdSuMa?dl=0). There are 5 files which indicate how the mentioned coins in the last two columns of the files were decided. For example, 'unmodified-symbol-or-name-in-subject-with-ANN----unmodified-symbol-and-name-in-subject-with-ANN-sorted-by-time' indicates that the last field contains the list of coins whose name and symbol were mentioned only in the subject; the second to last field in contrast contains the list of coins whose name or symbol were mentioned in the subject. In both cases, the post must have been tagged as announcment for the coin mentions to be counted. **Download these files and put them in a directory named 'forum-data' under the top-level repo directory.**
2. **Coins info with their earliest trade date**: https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/coins-with-earliest-trade-date.csv
3. **Verified announcements**: A list of 379 coin announcments that were manually verified either through candidates or by search over the forum. https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/verified_announcements.csv
4. **mapofcoins announcements**: A list of 593 coin announcement that were fetched from mapofcoins page. These are less reliable than verified announcements above, but nevertheless better than our candidates. Not all of these coins actually match the list of our coins in item 2 above. https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/ann_mapofcoins.csv

## Extract Introducer Candidates:
The current candidates are in *data/introducers/* in five different directories depending on how the coin mentions are detected:

1. unmodified-symbol-and-name-in-subject
2. unmodified-symbol-and-name-in-subject-content
3. unmodified-symbol-and-name-in-subject-with-ANN
4. unmodified-symbol-or-name-in-subject
5. unmodified-symbol-or-name-in-subject-with-ANN

The verified announcements are extracted from these candidates. We manually checked these candidates and used the one that was the best as the first announcement of the coin. If the forum-data changes or new coins are added to our list, you can regenerate the new set of candidates:

1. Update the top level directory in first line of [forums/commands/extract_users.sh](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/forums/commands/extract_users.sh)
2. Run *./forums/commands/extract_users.sh*

The new set of candidates will be written in *data/introducers/unlimited* directory. There will be a file containing introducing user info and another file containing the announcment URL per coin. You can compare them with current set of candidates in 
[data/verified_announcements.csv](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/verified_announcements.csv) which contains the list of 336 announcments we verified from the candidates.

## Extract Verified Introducer Info:
Note that we have two sets of verified announcements: [mapofcoin announcements](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/ann_mapofcoins.csv) and [manually verified announcements](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/verified_announcements.csv) from candidates. Once we have the verified announcment (and mapofcoins announcement) URLs we need to find the corresponding post and the announcer in the forums:

1. User info corresponding to verified announcers:

  ```
  ./forums/analysis/extract_posters.py         ./forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-and-name-in-subject-sorted-by-time.csv   ./data/coins-with-earliest-trade-date.csv ./data/verified_announcements.csv ./verified_output_dir
  ```
2. User info corresponding to mapofcoins announcers: 

  ```
  ./forums/analysis/extract_posters.py ./forum-data/unmodified-symbol-or-name-in-subject----unmodified-symbol-and-name-in-subject-sorted-by-time.csv ./data/coins-with-earliest-trade-date.csv ./data/ann_mapofcoins.csv ./mapofcoins_output_dir
  ```


There will be several output files in each output dir, but the main output file will be *coin_announcement.csv* which contains the user information corresponding to announcers listed in the input file. The format of this file is exactly the same as output from [forums/commands/extract_users.sh](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/forums/commands/extract_users.sh) in previous step.

## Join all introducer sources:
So far, we have three data sources containing the information about coin introducers, in the decreasing accuracy order:

1. Manually verified introducers: This will be the *verified_output_dir/coin_announcement.csv* output file from first command in the previous step. Current version of verified introducers info is [here](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/verified_introducers.csv).

2. Mapofcoin introducers: This will be the *mapofcoins_output_dir/coin_announcement.csv* output file from first command in the previous step. This file contains the user and post info of the announcement URL. Current version of mapofcoins introducers info is [here](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/mapofcoins_introducers.csv).

3. Unverified introducer candidates: These are contained in the output files from *extract_users.sh* command above. There will be several candidate sets using differene searching criteria. The three more accurate ones are: [unmodified-symbol-and-name-in-subject-with-ANN/unmodified_coin_first_thread_post_introducers.csv](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/unmodified-symbol-and-name-in-subject-with-ANN/unmodified_coin_first_thread_post_introducers.csv), [unmodified-symbol-and-name-in-subject/unmodified_coin_first_thread_post_introducers.csv](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/unmodified-symbol-and-name-in-subject/unmodified_coin_first_thread_post_introducers.csv) and [unmodified-symbol-and-name-in-subject-content/unmodified_coin_first_thread_post_introducers.csv](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/unmodified-symbol-and-name-in-subject-content/unmodified_coin_first_thread_post_introducers.csv).

We need to join these different sources of introducers into a single file, which we can later use as the input for computing network metrics of all coin introducers. We can do this using [join_introducers.py](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/forums/analysis/join_introducers.py). The script takes multiple introducer sources, and you should provide the input sources in the decreasing accuracy order. All the introducers in the first file will be included in the output, the second input source will be as a fallback for coins whose introducers was not included in the first file. The third will be as a fallback for the first and second and so on...

```
./forums/analysis/join_introducers.py ./verified_output_dir/coin_announcement.csv ./mapofcoins_output_dir/coin_announcement.csv ./data/introducers/unmodified-symbol-and-name-in-subject-with-ANN/unmodified_coin_first_thread_post_introducers.csv ./data/introducers/unmodified-symbol-and-name-in-subject/unmodified_coin_first_thread_post_introducers.csv ./data/introducers/unmodified-symbol-and-name-in-subject-content/unmodified_coin_first_thread_post_introducers.csv ./data/introducers/unmodified-symbol-or-name-in-subject-with-ANN/unmodified_coin_first_thread_post_introducers.csv ./data/introducers/unmodified-symbol-or-name-in-subject/unmodified_coin_first_thread_post_introducers.csv ./data/introducers/all_introducers.csv
```

The output will be *./data/introducers/all_introducers.csv*. The current output of this step is [all_introducers_concat.csv](https://github.com/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/blob/master/data/introducers/all_introducers_concat.csv). It contains introducer post info of 659 coins.

## Generate discussion networks:
In this step, we will generate the directed discussion networks in the forum for each day since the start of the forums. We will need the [processed forum data](https://www.dropbox.com/sh/grxbcuyo4cquyow/AABgnyGD0EtpJwrzfkgJdSuMa?dl=0) listed in the data description section above as the input. The output will be be a directory which contains an igraph network in pickle format for each day since 2009-11.

```
mkdir networks
./forums/commands/generate_directed_networks.sh
```

The bash script requires an input directory named 'forum-data' under the top-level repo directory containing the processed forum data. The output will be in networks/directed_unlimited directory.
