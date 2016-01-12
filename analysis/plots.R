input_filename = "./data/joined_price_network_btc.csv"
output_filename = "./images/severity_boxplot.pdf"
x_var = "user1_closeness_centrality_weighted"
#x_var = "user1_days_since_first_post"
y_var = "log_severity_to_average_after_max_volume_weighted"
#y_var = "magnitude"
#y_var = "log_magnitude"
xlabel = "Introducer Closeness Centrality"
#xlabel = "Introducer Days since First Post"
ylabel = "Severity"
#ylabel = "Magnitude"
legend_title = "Centrality Levels"
#legend_title = "Seniorty Levels"
y_min = 0
y_max= 6
num_bins = 10


library(ggplot2)
source("analysis/utils.R")
 
remove_zero_volume = FALSE 
if (dependent_var == "magnitude" | dependent_var == "log_magnitude") {
  remove_zero_volume = TRUE
}
data = read_data(input_filename, remove_zero_volume, normalize_closeness = TRUE, interaction_terms = FALSE)
data_size = nrow(data)
# 60% train
train_size = floor(0.60 * data_size)
# reporoducible partition?
set.seed(19870209)
train_indices = sample(seq(data_size), size = train_size)

train_data = data[train_indices, ]
test_data = data[-train_indices, ]

plot_data = data

x_data = plot_data[,x_var]
y_data = plot_data[,y_var]
min_rng=floor(min(x_data)*1000)/1000
max_rng=ceiling(max(x_data)*1000)/1000
bin_width = (max_rng - min_rng)/num_bins
rng = seq(min_rng, max_rng, bin_width)
#tick_labels = seq(min_rng + bin_width/2, max_rng, 2*bin_width)
tick_labels =  ggplot2:::interleave(seq(min_rng + bin_width/2, max_rng,by=2*bin_width), "")
legend_labels = paste(seq(min_rng, max_rng-bin_width, bin_width),
                      seq(min_rng+bin_width, max_rng, bin_width), sep="-")
tmp_df = data.frame(x = cut(x_data, breaks=rng),
                    y = y_data)
ggplot(data = tmp_df, aes(x=x, y=y)) +
  theme_bw() +
  theme(panel.border = element_rect(fill=NA, colour = "black", size=1),
        legend.key = element_blank(),
        axis.text = element_text(size=13),
        axis.title.x = element_text(size=14,vjust=-0.6),
        axis.title.y = element_text(size=14),
        legend.text = element_text(size=11),
        legend.title = element_text(size=12)) +
  labs(x = xlabel, y = ylabel) +
  guides(fill = guide_legend(title = legend_title)) +
  geom_boxplot(aes(fill = x)) +
  scale_x_discrete(labels=tick_labels) +
  scale_fill_discrete(labels = legend_labels) +
  ylim(y_min, y_max)
ggsave(output_filename, width=7, height=5)
