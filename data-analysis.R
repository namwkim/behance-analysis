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

#
##----- load data
#
behance = read.csv("/Users/namwkim85/Projects/behence-analysis/behance-users.csv")

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
a/b # male population is approximately 2.38 larger than female population

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
corrplot(cor(logFiltered), order="FPC")
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
#api call
cfs<-fromJSON("https://api.behance.net/v2/fields?client_id=ancBdHFrtqhJM18AUzqev2wvgjM0PGnj")
cfs$fields$abbr_name<-sapply( cfs$fields[2], function(x){
  tolower(gsub(" ", "_", x))
});

# preprocess behance$fields: three fields are seperated by '|'.
fields<-sapply(behance$fields, function(f){
  if (nchar(as.character(f))!=0){
    splited<-strsplit(as.character(f), "|", fixed = TRUE)
    unlist(splited)
  }
})

# topic vector
with(behance, {
  len<-length(fields)
})
a<-sapply(fields, function(f){
  fields<-cfs$fields$abbr_name
  vec<-rep(0, length(fields))
  if (length(f)>0){
    for (i in 1:length(f)){
      field<-tolower(gsub(" ", "_", f[i]))
      vec<- vec + as.integer(fields==field)  
    }
  }
  as.list(vec)
})

with(behance, sapply(fields, function(f){
  if (nchar(as.character(f))!=0){
    splited<-strsplit(as.character(f), "|", fixed = TRUE)
    
  }
}));

#
##----- deeper analysis on gender
#
# TODO: read reference papers
dens <- with(behance, tapply(log(followers), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)

dens <- with(behance, tapply(log(following), INDEX = gender, density))
df <- data.frame(
  x = unlist(lapply(dens, "[[", "x")),
  y = unlist(lapply(dens, "[[", "y")),
  cut = rep(names(dens), each = length(dens[[1]]$x))
)
plot_ly(df, x = x, y = y, color = cut)
with(behance, tapply(followers, gender, describe))
with(behance, tapply(project_appreciations, gender, describe))


#
##----- explore relationships between predictors and dependent variables 
#

#
##----- gender - country interaction
#


# alternative: zero-inflated model, but in my case, those zero values are legitimate values to keep...

ggplot(behance, aes(following, followers)) + geom_point(shape=1) + geom_smooth(method=lm)
ggplot(behance, aes(project_appreciations, followers)) + geom_point() + geom_smooth(method=lm)


m1 <- glm.nb(followers ~  project_appreciations + gender, data = behance, maxit = 100, trace=TRUE)
summary(m1)

m2 <- update(m2, .~.-gender)
summary(m2)
anova(m1, m2)

m3 <- glm(followers ~ project_appreciations + gender, family = "poisson", data = behance)
pchisq(2 * (logLik(m1) - logLik(m3)), df = 5, lower.tail = FALSE)
(est <- cbind(Estimate = coef(m1), confint(m1)))

