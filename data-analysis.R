##------------------------------
## Author: Nam Wook Kim
## HUID: 90948148
## Date: Dec 10, 2015
##------------------------------

# require packages
if (!require(plyr)) {install.packages("plyr"); require(plyr)}           
if (!require(psych)) {install.packages("psych"); require(psych)}           
if (!require(graphics)) {install.packages("graphics"); require(graphics)}      
if (!require(maps)) {install.packages("maps"); require(maps)}      
if (!require(ggplot2)) {install.packages("ggplot2"); require(ggplot2)}      
if (!require(plotly)) {install.packages("plotly"); require(plotly)}      
if (!require(countrycode)) {install.packages("countrycode"); require(countrycode)}      
if (!require(MASS)) {install.packages("MASS"); require(MASS)}      
if (!require(pscl)) {install.packages("pscl"); require(pscl)}    
if (!require(QuantPsyc)) {install.packages("QuantPsyc"); require(QuantPsyc)}    
if (!require(reshape2)) {install.packages("reshape2"); require(reshape2)} 
if (!require(corrplot)) {install.packages("corrplot"); require(corrplot)} 
if (!require(princomp)) {install.packages("princomp"); require(princomp)} 
if (!require(jsonlite)) {install.packages("jsonlite"); require(jsonlite)} 
if (!require(hash)) {install.packages("hash"); require(hash)} 
if (!require(relaimpo)) {install.packages("relaimpo"); require(relaimpo)}  
if (!require(lmtest)) {install.packages("lmtest"); require(lmtest)}  
if (!require(MASS)) {install.packages("MASS"); require(MASS)}  
#
##----- load data
#
behance = read.csv("https://raw.githubusercontent.com/namwkim/behance-analysis/master/behance-users.csv")

#
##----- distribution of signed-up dates
#
# convert timestamp to readable format
dates<-as.Date(as.POSIXct(behance$created_on, origin="1970-01-01"))
dates<-data.frame(table(dates))
plot_ly(dates, x=dates, y=Freq) %>% 
  add_trace(y = fitted(loess(Freq ~ as.numeric(dates))))
# : to confirm that I actually collected active users


#
##----- # of users by gender 
#
allgender<-subset(behance, gender=="male"|gender=="female")
male<-subset(behance, gender=="male" )
female<-subset(behance, gender=="female" )
unknown<-subset(behance, gender=="unknown" )
nrow(allgender)
nrow(male)
nrow(female)
nrow(unknown)

# Male population is approximately 2.38 larger than female population
# It's surprising in that
#    1) compared to Pinterest whose female population is significantly higher than male population
#    2) creative fields such as graphic design are usually associated with women, I think.
# *it's possible this is the problem of my sampling strategy. 

#
##----- # of users by countries
#
topCountries<-function(d){
  c<-count(d, "country")
  c<-c[order(-c$freq),]
  c
}
totalP<-topCountries(behance)
allGenderP<-topCountries(allgender)
maleP<-topCountries(male)
femaleP<-topCountries(female) 
# After gender inferences, rankings change a bit. 
#   For instance, asian names' genders were not accurately inferred (rank 4 > 19)
#   But, most rankings remain similar after the gender prediction.
cbind(totalP[1:20, ], allGenderP[1:20, ]) 
cbind(maleP[1:20, ], femaleP[1:20, ])  # top 5 remain the same across gender

#
##----- world choropleth map of population
#

# convert country names to country codes
totalP$country_code <-countrycode(totalP$country, "country.name", "iso3c")
totalP<-na.omit(totalP) # remove missing data
# draw map 
l <- list(color = toRGB("grey"), width = 0.5)
g <- list(
  showframe = FALSE,
  showcoastlines = FALSE,
  projection = list(type = 'Mercator')
)
plot_ly(totalP, z = freq, text = country, locations = country_code, type = 'choropleth',
        color = freq, colors = 'Reds', marker = list(line = l),
        colorbar = list(title = 'User Count', thickness=15, ypad=200)) %>%
  layout(title="Population By Countries", geo=g)

#
##----- u.s choropleth map (since it has the most population)
#
usdata<-behance[behance$country=="United States",]
statecount<-count(usdata, 'state')
statecount$state_code<-state.abb[match(statecount$state, state.name)]
statecount<-na.omit(statecount)
g <- list(
  scope = 'usa',
  projection = list(type = 'albers usa'),
  showlakes = TRUE,
  lakecolor = toRGB('white')
)
plot_ly(statecount, z = freq, text = state, locations = state_code, type = 'choropleth',
        locationmode = 'USA-states', color = freq, colors = 'Reds', marker = list(line = l),
        colorbar = list(title = "User Count", thickness=15, ypad=200)) %>%
  layout(title = 'Population by Users', geo = g)
# : california & new your has the most population as expected

#
##----- descriptive statistics of behance data
#
summary(behance)
summary(allgender) # after gender inference
describe(behance$followers)
describe(allgender$followers)
describe(behance$project_appreciations)
describe(allgender$project_appreciations)

#
##----- kernal density plots of numeric variables
#
drops<-c("following", "followers",
         "project_counts", "project_views", "project_appreciations", "project_comments",
         "collection_counts", "collection_item_counts", "collection_followers",
         "wip_counts", "wip_views", "wip_comments", "wip_revisions")

plotDensity<-function(data){
  measures<-data[, (names(data) %in% drops)] # only numeric variables
  
  logFiltered<- log(measures + 1) # HACK: to handle zero values
  melted<-melt(logFiltered) # long format
  colnames(melted)<-c("measure", "count")
  dens <- with(melted, tapply(count, INDEX = measure, density))
  df <- data.frame(
    x = unlist(lapply(dens, "[[", "x")),
    y = unlist(lapply(dens, "[[", "y")),
    cut = rep(names(dens), each = length(dens[[1]]$x))
  )
  plot_ly(df, x = x, y = y, color = cut)
  
}
# tip: unselect legends interactively to only see measures of interest 

plotDensity(behance)
plotDensity(allgender)
# distribution looks similar
# so from now on, I will use the 'allgender' data that has gender attributes.

#
##----- correlatin between predictors
#

measures<-allgender[, (names(allgender) %in% drops)] # only numeric variables
corrplot(cor(measures), order="FPC")
# see highly correlated groups
# group1: project_appreciations, project_comments, project_views, followers
# group2: wip_comments, wip_views
# group3: wip_revisions, wip_counts
# group4: project_counts
# - it's interesting that project counts are not necessarily correlated with other project-related measures
# group5: following
# - this is also not necessarily correlated with "follwers"
# group6: collection_followers, collection_item_counts
# group7: collection counts

# At a higher level, project, wip, collection related measures create a loosely coupled groups

#
##----- specialization (which topic is the most popular one and by which gender)
#

# API call to retrieve pre-defined popular creative fields from behance
cfs<-fromJSON("https://api.behance.net/v2/fields?client_id=ancBdHFrtqhJM18AUzqev2wvgjM0PGnj")
# clean the fields 
cfs$fields$abbr_name<-sapply( cfs$fields[2], function(x){
  tolower(gsub(" ", "_", x))
});
systemFields<-as.vector(cfs$fields$abbr_name)

# calculate topic rankings of users' fields
calcTopicRanks<-function(fields){
  userFields<-hash() 
  a<-sapply(fields, function(f){
    if (nchar(as.character(f))!=0){
      # process users' fields concatenated by '|'
      splited<-strsplit(as.character(f), "|", fixed = TRUE)
      splited<-unlist(splited)
      for (i in 1:length(splited)){
        field<-tolower(gsub(" ", "_", splited[i]))
        if (has.key(field, userFields)==FALSE){
          userFields[[field]]<-0
        }
        userFields[[field]]<-userFields[[field]]+1
      }
    }
  })
  # sort by the number of users for topics
  userFields<-sort(values(userFields), decreasing=TRUE)
  # return user fields
  userFields
}
# visualize the rankings (up to # rankings)
visualizeRanks<-function(fields, upto){
  ranks<-data.frame(fields=names(fields[1:upto]), counts=fields[1:upto])
  # reorder factors to match colors and bars
  ranks$fill<-factor(ranks$fields, levels = ranks$fields[order(ranks$counts, decreasing=TRUE)])
  ranks$x<-as.character(1:length(ranks$fields))
  ranks$x<-factor(ranks$x, levels = ranks$x[order(ranks$counts, decreasing=TRUE)])
  ggplot(ranks, aes(x=x, y=counts, fill= fill)) + 
    geom_bar(stat="identity") + 
    guides(fill=guide_legend(ncol=2)) + 
    labs(list(x="Fields", y="Users", fill = "Fields"))
}
# calc ranks (warning: slow)
userFields<-calcTopicRanks(allgender$fields)
maleFields<-calcTopicRanks(male$fields)
femaleFields<-calcTopicRanks(female$fields)
visualizeRanks(userFields, 20) 
visualizeRanks(femaleFields, 20) 
visualizeRanks(maleFields, 20) 

# field diversities
length(systemFields)
length(userFields)
length(maleFields)
length(femaleFields)

#compare with system's popular fields
cbind(names(head(userFields, n=12)),cfs$popular$name)
# : system's  popular fields seemed to be picked based on diversity, not actual popularities.

#compare between genders
cbind(names(head(maleFields, n=12)),names(head(femaleFields, n=12)))
# : web site & ux/ui do not appear in women's rankings, while they have fashion & editorial_design

#
##----- prepare for further analysis
#
# add binary category variables (whether a user has a certain field or not)
createCategoryVars<-function(data, field_names){
  for (i in 1:length(field_names)){
    print(paste("creating a variable name of ", paste("has_", field_names[i], sep="")))
    data[, paste("has_", field_names[i],sep="")]<-as.logical(sapply(data$fields, function(f){
      if (nchar(as.character(f))!=0){
        fields<-tolower(gsub(" ", "_", as.character(f)))
        grepl(field_names[i], fields)
      }else{
        FALSE
      }
    }))
  }
  data
}

allgender<-createCategoryVars(allgender, names(userFields[1:15]))
count(allgender$has_graphic_design) #sanity check


# add binary country variables
createCountryVars<-function(data, country_names){
  for (i in 1:length(country_names)){
    print(paste("creating a variable name of ", paste("from_", country_names[i], sep="")))
    n<-tolower(gsub(" ", "_", as.character(country_names[i])))
    data[, paste("from_",n, sep="")]<-data$country==country_names[i]
  }
  data
}
allgender<-createCountryVars(allgender, as.character(factor(allGenderP[1:10, ]$country)))
count(allgender$from_united_states) #sanity check

# fix factor level (remove unknown)
allgender$gender<-factor(allgender$gender)


#
##----- further exploration of data
#
dens <- with(allgender, tapply(log(followers+1), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)
with(allgender, tapply(followers, gender, describe))
# female has a lower median and but also more mass in the tail of their follower distribution

dens <- with(allgender, tapply(log(project_appreciations+1), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)
with(allgender, tapply(project_appreciations, gender, describe))
# same as above, women has relatively lower median of project appreciations.
# -> nothing interesting

# take a deeper look at the difference in topical rankings 
allPhoto<-subset(allgender, allgender$has_digital_photography==1)
allGraphic<-subset(allgender, allgender$has_graphic_design==1)
describe(allGraphic$project_appreciations)
describe(allPhoto$project_appreciations)
describe(allGraphic$followers)
describe(allPhoto$followers)
# while graphic_design is the most popular, 
#  digital photography seems to have more followers and project appreciations

allUS<-subset(allgender, allgender$from_united_states==1)
allBrazil<-subset(allgender, allgender$from_brazil==1)
allItaly<-subset(allgender, allgender$from_italy==1)

describe(allUS$followers)
describe(allBrazil$followers)
describe(allItaly$followers) # Italy is top among three (median)
describe(allUS$project_appreciations)
describe(allBrazil$project_appreciations)
describe(allItaly$project_appreciations) # Italy is top among three (median)
#
##----- prediction model #1 : negative binomial regression
#
# RQ. What structures connections?
# DV. # of followers
# IV. all other attributes
# alternative: zero-inflated model, but zero values seem legitimate in my case, not generated by other processes

# remove unused attributes 
#  * I don't use wip-related attributes as they are too small (users don't use it much yet)
regdata<-allgender[, c(5, 11:19, 24:48)]
names(regdata)

##fit a regression on all predictors 
fitnb <- glm.nb(followers ~ ., data = regdata, maxit = 100, trace=TRUE)
summary(fitnb)

# relative importance of predictors
beta_std <- lm.beta(fitnb)        
rel_beta_std<-beta_std/sum(beta_std)
sort(rel_beta_std, decreasing = TRUE)

# Interpretation:
# Project appreciations has the most predictive power on the DV.
# Collection has no predictive power on the DV. Unlike Pinterest, collection is not popularly used by users. This aligns with the purpose of Behance.
# Having graphic design projects negatively affects the DV. While it’s the most popular topic, this may indicate the field name ‘graphic design’ is too general to attract users.
# While Brazil has the second most user population, it has an negative impact on the DV.

fit<-update(fitnb, .~. -collection_counts-collection_item_counts -collection_followers
               -has_digital_photography-from_italy-from_india)
anova(fitnb, fit)
summary(fit)
AIC(fit) # need more experiments to find the final best model.
AIC(fitnb) 

# variable selection (error occurred)
# fitnb_back <- stepAIC(fitnb, trace=FALSE)
# summary(fitnb_back)


#
##----- prediction model #2 : negative binomial regression
#
# Q. What structures connections?
# DV. # of project appreciations
# IV. all other attributes

##fit a regression on all predictors 
fitnb_pa <- glm.nb(project_appreciations ~ ., data = regdata, maxit = 100, trace=TRUE)
summary(fitnb_pa)

# relative importance of predictors
beta_std <- lm.beta(fitnb_pa)        
sort(beta_std, decreasing = TRUE)

# Interpretation:
# Project related features (e.g. counts, views) have the most predictive power.
# Interestingly, collection related features (e.g. counts) have significant importance as well.
# I later found that a user can create a collection of their own projects.
# If you are from the U.S, you are likely to receive less appreciations.

fit_pa<-update(fitnb_pa, .~. -collection_followers
            -from_united_states
            -from_brazil-from_india-from_egypt-from_mexico-collection_followers)
anova(fitnb_pa, fit_pa)
summary(fit_pa)
AIC(fit_pa) # doesn't really improve the model
AIC(fitnb_pa)

# variable selection 
# : commented because it's too slow
# : results ::  only collection_followers is removed from the full model

# fitnb_pa_back <- stepAIC(fitnb_pa, trace = FALSE)
# summary(fitnb_pa_back)
# modvar <- names(coef(fitnb_pa_back))
# modvar
# fullvar <- names(coef(fitnb_pa))
# fullvar
# excluded <- !fullvar %in% modvar   ## compare strings
# fullvar[excluded]