library(glmnet)
library(MASS)
library(sandwich)
library(lmtest)
library(stargazer)
setwd(dir = "~/research/nikete/Comunity-Structure-Extremely-Speculative-Asset-Dynamics/")
source("analysis/elastic_net.R")
setwd(dir = "data")
data = read.csv(file = "joined_price_network_usd.csv", header = TRUE, sep = ",")
data$earliest_mention_date = as.character(data$earliest_mention_date, format = "%Y-%m-%d")
data$network_date = as.character(data$network_date, format = "%Y-%m-%d")
data$earliest_trade_date = as.character(data$earliest_trade_date, format = "%Y-%m-%d")
data$log_severity_to_average_after_max_volume_weighted = log(data$severity_to_average_after_max_volume_weighted)
data$magnitude = data$normalized_total_volume_before_max / data$normalized_total_volume
# fix infinite satoshi distance
data$user1_satoshi_distance_inf = data$user1_satoshi_distance>7
data$user1_satoshi_distance[data$user1_satoshi_distance_inf] = 7

# remove btc if present
data = data[data$symbol != "BTC",]

data_size = nrow(data)
# 60% train
train_size = floor(0.60 * data_size)
# reporoducible partition?
set.seed(19870209)
train_indices = sample(seq(data_size), size = train_size)

train_data = data[train_indices, ]
test_data = data[-train_indices, ]

all_independent_vars =  c("user1_num_posts",
                          "user1_num_subjects",
                          "user1_days_since_first_post",
                          "user1_degree_incoming",
                          "user1_degree_outgoing",
                          "user1_clustering_coefficient",
                          "user1_closeness_centrality_unweighted",
                          "user1_closeness_centrality_weighted",
                          "user1_closeness_centrality_incoming_unweighted",
                          "user1_closeness_centrality_outgoing_unweighted",
                          "user1_closeness_centrality_incoming_weighted",
                          "user1_closeness_centrality_outgoing_weighted",
                          "user1_betweenness_centrality_weighted",
                          "user1_satoshi_distance",
                          "user1_satoshi_distance_inf",
                          "user1_satoshi_pagerank_unweighted",
                          "user1_satoshi_pagerank_weighted",
                          "user1_pagerank_unweighted",
                          "user1_pagerank_weighted")
cor(train_data[,all_independent_vars])
cor(train_data[,all_independent_vars])>0.9


#####################################
# Model 0: Initial exploration, using all vars. No specific model
# find the best elastic net model config and get nonzero coefficients on best alpha 
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_outgoing",
                           "user1_clustering_coefficient",
                           "user1_closeness_centrality_weighted",
                           "user1_betweenness_centrality_weighted",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
                           "user1_satoshi_pagerank_weighted",
                           "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)
# plot the cross validated alpha results
cvfit = cv.glmnet(x, y, nfolds=5, type.measure="mse", standardize=T, alpha=best_alpha)
plot(cvfit)
cvfit$lambda.min
coef(cvfit, s="lambda.min")

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
lmfit = lm(as.formula(lm_formula), train_data)
summary(lmfit)

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(lmfit) > 30/nrow(train_data)), c("coin_name", "symbol", dependent_var, nonzero_coefs)]

# get robust standard errors
robust_se = diag(vcovHC(lmfit, type="HC"))^0.5
coeftest(lmfit, vcov=vcovHC(lmfit, "HC0"))
coeftest(lmfit, vcov=vcovHC(lmfit, "HC2"))
coeftest(lmfit, vcov=vcovHC(lmfit, "HC3"))



# run robust regression using iterated re-weighted least square
rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
wlmfit = lm(as.formula(lm_formula), train_data, weights=rlmfit$w)
summary(wlmfit)

# check the weights assigned to each coin
weights = data.frame(coin=train_data[,"coin_name"], log_severity=train_data[,dependent_var], residual=rlmfit$residuals, weight = rlmfit$w)
weights_ordered = weights[order(rlmfit$w),]
weights_ordered[1:15,]


#####################################
# Model 1: Use only simple user stats
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_outgoing")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model1_lmfit = lm(as.formula(lm_formula), train_data)
model1_lm_sum = summary(model1_lmfit)
model1_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model1_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model1_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model1_rlm_sum = model1_lm_sum
model1_rlm_sum$coefficients = unclass(coeftest(model1_lmfit, vcov=vcovHC(model1_lmfit, "HC0")))
model1_rlm_sum

# run robust regression using iterated re-weighted least square
model1_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model1_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model1_wlmfit = lm(as.formula(lm_formula), train_data, weights=model1_rlmfit$w)
summary(model1_wlmfit)




#####################################
# Model 2: Use only vars relative to satoshi
good_independent_vars =  c("user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
                           "user1_satoshi_pagerank_weighted")
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model2_lmfit = lm(as.formula(lm_formula), train_data)
model2_lm_sum = summary(model2_lmfit)
model2_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model2_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model2_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model2_rlm_sum = model2_lm_sum
model2_rlm_sum$coefficients = unclass(coeftest(model2_lmfit, vcov=vcovHC(model2_lmfit, "HC0")))
model2_rlm_sum

# run robust regression using iterated re-weighted least square
model2_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model2_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model2_wlmfit = lm(as.formula(lm_formula), train_data, weights=model2_rlmfit$w)
summary(model2_wlmfit)



#####################################
# Model 3: Use network measures
good_independent_vars =  c("user1_clustering_coefficient",
                           "user1_closeness_centrality_weighted",
                           "user1_betweenness_centrality_weighted",
                           "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model3_lmfit = lm(as.formula(lm_formula), train_data)
model3_lm_sum = summary(model3_lmfit)
model3_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model3_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model3_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model3_rlm_sum = model3_lm_sum
model3_rlm_sum$coefficients = unclass(coeftest(model3_lmfit, vcov=vcovHC(model3_lmfit, "HC0")))
model3_rlm_sum

# run robust regression using iterated re-weighted least square
model3_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model3_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model3_wlmfit = lm(as.formula(lm_formula), train_data, weights=model3_rlmfit$w)
summary(model3_wlmfit)




#####################################
# Model 4: Use all vars
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_outgoing",
                           "user1_clustering_coefficient",
                           "user1_closeness_centrality_weighted",
                           "user1_betweenness_centrality_weighted",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
                           "user1_satoshi_pagerank_weighted",
                           "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

# find the best elastic net model config and get nonzero coefficients on best alpha 
alphas=seq(1,1,by=0.05)
best_model = cross_validate_alphas(x, y, alphas)
best_alpha = best_model[2]
nonzero_coefs = extract_nonzero_coefs(best_model$coefs)

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model4_lmfit = lm(as.formula(lm_formula), train_data)
model4_lm_sum = summary(model4_lmfit)
model4_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model4_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model4_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model4_rlm_sum = model4_lm_sum
model4_rlm_sum$coefficients = unclass(coeftest(model4_lmfit, vcov=vcovHC(model4_lmfit, "HC0")))
model4_rlm_sum

# run robust regression using iterated re-weighted least square
model4_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model4_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model4_wlmfit = lm(as.formula(lm_formula), train_data, weights=model4_rlmfit$w)
summary(model4_wlmfit)


#####################################
# Model 5: Use all vars without feature selection
good_independent_vars =  c("user1_num_posts",
                           "user1_num_subjects",
                           "user1_days_since_first_post",
                           "user1_degree_incoming",
                           "user1_degree_outgoing",
                           "user1_clustering_coefficient",
                           "user1_closeness_centrality_weighted",
                           "user1_betweenness_centrality_weighted",
                           "user1_satoshi_distance",
                           "user1_satoshi_distance_inf",
                           "user1_satoshi_pagerank_weighted",
                           "user1_pagerank_weighted")
cor(train_data[,good_independent_vars])>0.9
dependent_var = "log_severity_to_average_after_max_volume_weighted"
x = data.matrix(train_data[,good_independent_vars])
y = train_data[,dependent_var]

nonzero_coefs = good_independent_vars

# Run simple ols
lm_formula = paste(dependent_var, "~", paste(nonzero_coefs, collapse=" + "))
model5_lmfit = lm(as.formula(lm_formula), train_data)
model5_lm_sum = summary(model5_lmfit)
model5_lm_sum

# investigate the assumption of ols
oldpar = par(mfrow = c(2,2))
plot(model5_lmfit, las=1)
par(oldpar)
train_data[which(cooks.distance(model5_lmfit) > 30/nrow(train_data)), c("coin_name", dependent_var, nonzero_coefs)]

# Get summary with robust standard errors
model5_rlm_sum = model5_lm_sum
model5_rlm_sum$coefficients = unclass(coeftest(model5_lmfit, vcov=vcovHC(model5_lmfit, "HC0")))
model5_rlm_sum

# run robust regression using iterated re-weighted least square
model5_rlmfit = rlm(as.formula(lm_formula), train_data, psi="psi.huber", method="M", model=T)
summary = summary(model5_rlmfit)
dd = data.frame(summary$coefficients)
dd$p.value = 2*pt(abs(dd$t.value), summary$df[2], lower.tail=FALSE)
dd
# above uses the psi.huber penalty function. but below we simply use mse.
# the results are similar nevertheless.
model5_wlmfit = lm(as.formula(lm_formula), train_data, weights=model5_rlmfit$w)
summary(model5_wlmfit)



#####################################
# Print table
order =  c("user1_num_posts",
           "user1_num_subjects",
           "user1_days_since_first_post",
           "user1_degree_incoming",
           "user1_degree_outgoing",
           "user1_clustering_coefficient",
           "user1_closeness_centrality_weighted",
           "user1_betweenness_centrality_weighted",
           "user1_satoshi_distance",
           "user1_satoshi_distance_inf",
           "user1_satoshi_pagerank_weighted",
           "user1_pagerank_weighted")
cov.labels = c("Number of posts",
               "Number of subject",
               "Days since first post",
               "Incoming degree",
               "Outgoing degree",
               "Clustering coefficient",
               "Closeness centrality",
               "Betweenness centrality",
               "Satoshi distance",
               "Infinite Satoshi distance",
               "Satoshi pagerank",
               "Pagerank")
depvar.label = c("Severity")
stargazer(model1_wlmfit,
          model2_wlmfit,
          model3_wlmfit,
          model4_wlmfit,
          model5_wlmfit,
          dep.var.labels= "",
          column.labels=c("Model1","Model2", "Model3", "Model4", "Model5", "Model6"),
          column.sep.width = "3pt",
          omit.table.layout = "#",
          df = FALSE,
          title="", align=TRUE,
          dep.var.caption = depvar.label,
          order = order,
          covariate.labels = cov.labels,
          float.env = "table*",
          digits = 3,
          out="../tables/log_severity.tex")