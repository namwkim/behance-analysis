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

#
##----- load data
#
behance = read.csv("https://raw.githubusercontent.com/namwkim/behance-analysis/master/behance-users.csv")

#
##----- signed-up dates (to confirm that I collected active users)
#
dates<-as.Date(as.POSIXct(behance$created_on, origin="1970-01-01"))

dates<-data.frame(table(dates))

plot_ly(dates, x=dates, y=Freq) %>% 
  add_trace(y = fitted(loess(Freq ~ as.numeric(dates))))

#
##----- # of users by gender
#
male<-subset(behance, gender=="male" )
female<-subset(behance, gender=="female" )
a<-nrow(male)
a
b<-nrow(female)
b
c<-nrow(subset(behance, gender=="unknown" ))
c
a+b+c # should be 50,000
a/b 
# male population is approximately 2.38 larger than female population
# quite surprising 
#    1) need to look at each field
#    2) compared to Pinterest whose the majority of population is female.


#
##----- # of users by countries
#
top20countries<-function(d){
  c<-count(d, "country")
  c<-c[order(-c$freq),]
  print(head(c, 20))
  c
}
totalP<-top20countries(behance)
maleP<-top20countries(male)
femaleP<-top20countries(female) # top 5 remain the same across gender

##-- world choropleth map
totalP$country_code <-countrycode(totalP$country, "country.name", "iso3c")
l <- list(color = toRGB("grey"), width = 0.5)
g <- list(
  showframe = FALSE,
  showcoastlines = FALSE,
  projection = list(type = 'Mercator')
)
totalP<-na.omit(totalP)
totalP$country_code

plot_ly(totalP, z = freq, text = country, locations = country_code, type = 'choropleth',
        color = freq, colors = 'Reds', marker = list(line = l),
        colorbar = list(title = 'User Count', thickness=15, ypad=200)) %>%
  layout(title="Population By Countries", geo=g)

##-- u.s choropleth map
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

#
##----- descriptive statistics of behance data
#
summary(behance)

#
##----- kernal density plots (check skewness) of numeric variables
#

drops<-c("following", "followers", 
         "project_counts", "project_views", "project_appreciations", "project_comments",
         "collection_counts", "collection_item_counts", "collection_followers",
         "wip_counts", "wip_views", "wip_comments", "wip_revisions")
measures<-behance[, (names(behance) %in% drops)] # only numeric variables

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
# : unselect legends interactively to closely see measures of interest 
#    It seems there are wiggles and dense zero values for some measures (i.e. non-normal)


#
##----- correlatin between predictors
#
corrplot(cor(measures), order="FPC")
# : observed groupings along project, collection, and wip

# pca also revelas that each group of variables vary together 
# fit<-princomp(measures, cor=TRUE)
# summary(fit)
# loadings(fit)
# plot(fit,type="lines")
# biplot(fit) # too slow

#
##----- specialization (which topic is the most popular one and by which gender)
#
#api call to retrieve creative fields from behance
cfs<-fromJSON("https://api.behance.net/v2/fields?client_id=ancBdHFrtqhJM18AUzqev2wvgjM0PGnj")
cfs$fields$abbr_name<-sapply( cfs$fields[2], function(x){
  tolower(gsub(" ", "_", x))
});
systemFields<-as.vector(cfs$fields$abbr_name)
# preprocess behance$fields: three fields for each user seperated by '|'

calcTopicRanks<-function(fields){
  userFields<-hash() #keys=allFields, values=rep(0, length(allFields)))
  # slow. loop over 50,000 entries
  a<-sapply(fields, function(f){
    if (nchar(as.character(f))!=0){
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
  # sort by the number of users
  userFields<-sort(values(userFields), decreasing=TRUE)
  # return user fields
  userFields
}
visualizeRanks<-function(fields, upto){
  # visualize up to 30 ranks
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
# calc ranks
userFields<-calcTopicRanks(behance$fields)
maleFields<-calcTopicRanks(male$fields)
femaleFields<-calcTopicRanks(female$fields)
visualizeRanks(femaleFields, 20) 
visualizeRanks(maleFields, 20) 

# field diversities
length(systemFields)
length(userFields)
length(maleFields)
length(femaleFields)

#compare with system's popular fields
cbind(names(head(userFields, n=12)),cfs$popular$name)
#compare between genders
cbind(names(head(maleFields, n=12)),names(head(femaleFields, n=12)))
# system's  popular fields seemed to be picked based on topics, not actual popularities.
# web site & ux/ui do not appear in women's rankings- quite suprising.

#
##----- deeper analysis on gender
#
#  
dens <- with(behance, tapply(log(followers), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)

dens <- with(behance, tapply(log(project_appreciations), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)

with(behance, tapply(followers, gender, describe))

with(behance, tapply(project_appreciations, gender, describe))
# men seem to have more followers and more project appreciations.

#
##----- explore relationships between predictors and dependent variables 
#

#
##----- gender - country interaction
#


#
##----- prediction model : negative binomial regression
#

# prepare for regression model

# 
# alternative: zero-inflated model, 
regdata<-subset(behance, gender=="female" | gender=="male")
regdata$from_us <- regdata$country=="United States"
regdata$from_br <- regdata$country=="Brazil"
regdata$from_uk <- regdata$country=="United Kingdom"
regdata$from_it <- regdata$country=="Italy"
regdata$from_rs <- regdata$country=="Russian Federation"

m1 <- glm.nb(followers ~ 1, data = regdata, maxit = 100, trace=TRUE)
m2 <- update(m1, .~.+project_appreciations)
anova(m1, m2)
m3 <- update(m2, .~.+project_comments)
anova(m2, m3)
m4 <- update(m3, .~.+project_views)
anova(m3, m4)
m5 <- update(m4, .~.+wip_comments)
anova(m4, m5)
# m6 <- update(m5, .~.+wip_views) # error
# anova(m4, m5)
# m6 <- update(m5, .~.+wip_revisions) #error
# anova(m4, m5)
# m6 <- update(m5, .~.+wip_counts) # doesn't converge
# anova(m5, m6)
m6 <- update(m5, .~.+project_counts)
anova(m5, m6)
m7 <- update(m6, .~.+following)
anova(m6, m7)
m8 <- update(m7, .~.+collection_followers) # this doesn't improve the model
anova(m7, m8)
m8 <- update(m7, .~.+collection_item_counts) # so as this
anova(m7, m8)
m8 <- update(m7, .~.+collection_counts) # so as this too
anova(m7, m8)
m8 <- update(m7, .~.+gender) 
anova(m7, m8)


summary(fitNegBin)

# m2 <- update(m1, .~.-gender)
# summary(m2)
# anova(m1, m2)
# 
# m3 <- glm(followers ~ project_appreciations + gender, family = "poisson", data = behance)
# pchisq(2 * (logLik(m1) - logLik(m3)), df = 5, lower.tail = FALSE)
# (est <- cbind(Estimate = coef(m1), confint(m1)))

