
##------------------------------------------------------------
## Author: Charles Dorison & Nam Wook Kim
## Date: Dec 10, 2015
##------------------------------------------------------------

library(foreign)
require(gdata)
if (!require(pastecs)) {install.packages("pastecs"); require(pastecs)}   
if (!require(car)) {install.packages("car"); require(car)} 
if (!require(psych)) {install.packages("psych"); require(psych)} 
install.packages(c("psych","GPArotation","MASS")); require(psych)
if (!require(corrplot)) {install.packages("corrplot"); require(corrplot)}  
if (!require(mvtnorm)) {install.packages("mvtnorm"); require(mvtnorm)}  
if (!require(boot)) {install.packages("boot"); require(boot)}   
if (!require(dplyr)) {install.packages("dplyr"); require(dplyr)}  
if (!require(lmPerm)) {
  install.packages("http://cran.r-project.org/src/contrib/Archive/lmPerm/lmPerm_1.1-2.tar.gz", type = "source", repos = NULL)
  require(lmPerm)}
if (!require(coin)) {install.packages("coin"); require(coin)}          
if (!require(pastecs)) {install.packages("pastecs"); require(pastecs)}        
if (!require(pgirmess)) {install.packages("pgirmess"); require(pgirmess)}         
if (!require(WRS2)) {install.packages("WRS2"); require(WRS2)}           


if (!require(lattice)) install.packages("lattice"); require(lattice)
if (!require(ape)) install.packages("ape"); require(ape)
if (!require(vioplot)) install.packages("vioplot"); require(vioplot)
if (!require(rgl)) install.packages("rgl"); require(rgl)
if (!require(scatterplot3d)) install.packages("scatterplot3d"); require(scatterplot3d)
if (!require(misc3d)) install.packages("misc3d"); require(misc3d)
if (!require(MASS)) install.packages("MASS"); require(MASS)
if (!require(animation)) {install.packages("animation"); require(animation)}
if (!require(googleVis)) {install.packages("googleVis"); require(googleVis)}
if (!require(WDI)) {install.packages("WDI"); require(WDI)}
if (!require(igraph)) install.packages("igraph"); require(igraph)

if (!require(lme4)) install.packages("lme4"); require(lme4)              ## package for mixed-effects models
if (!require(lmerTest)) install.packages("lmerTest"); require(lmerTest)  ## gives p-values for lme4
if (!require(pbkrtest)) install.packages("pbkrtest"); require(pbkrtest)     ## LR-tests for mixed-effect models
require(reshape)
require(nlme)
require(lattice)
require(boot)

if (!require("betareg")) {install.packages("betareg"); require("betareg")}
if (!require(ngramr)) install.packages("ngramr"); require(ngramr)

if (!require(compute.es)) {install.packages("compute.es"); require(compute.es)}  ## effect size package
if (!require(effsize)) {install.packages("effsize"); require(effsize)}  
if (!require(pwr)) {install.packages("pwr"); require(pwr)} 

#Let's first read our dataset into R from excel
dataset <- read.csv("DorisonPsych1950FinalData", header = TRUE)


# Some general summary statistics
names(dataset)
summary(dataset)
describe(dataset)

# Let's also set our condition as a factor before we get started with analyses
group <- as.factor(rep(c("control", "gratitude", "happiness"), each = 25))
dataset[, "condition"] <- group

attach(dataset)

# Overview of this report
# Section 1: Emotion Measures, Pre-Analyses, and Assumption Checks
# Section 2: Manipulation Check (slightly artificial mixed effect models)
# Section 3: Beta Regression of Emotion on Financial Patience
# Section 4: Practicing other Relevant Tools

##------------------- Section 1: Emotion Measures, Pre-Analyses, and Assumption Checks -------------------------

# Section Overview
# Part 1: Creation of gratitude and happiness measures
# Part 2: Descriptive Analyses, Correlational Analyses, Basic Plotting, Advanced Plotting
# Part 3: Assumption Checks for Mixed Effect Model

## Part 1: Creation of gratitude and happiness measures

# Note: Some more advanced factor analysis might be necessary here to make sure that all three items contribute equally to the scale. 
# I'll do some correlational analyses to make sure that they're each highly correlated with each other, as we haven't learned factor analyses yet. 
# Additionally, could do a cronbach's alpha calculation for each scale. I'll do correlational analysis and advanced plotting in place of these. 
Happinesstotal = happy + content + pleasan
Happinesstotal
IndexHappiness = Happinesstotal/3
IndexHappiness

Gratitudetotal = grateful + appreciative + thankful
Gratitudetotal
IndexGratitude = Gratitudetotal/3
IndexGratitude

detach(dataset)
dataset[, "IndexGratitude"] <- IndexGratitude
dataset[, "IndexHappiness"] <- IndexHappiness
attach(dataset)

## Part 2: 
# A. Descriptive Analyses
# B. Correlational Analyses
# C. Basic Plotting
# D. Advanced Plotting

# A. Descriptive Analyses

## Means and medians are both relatively high across conditions; could have a ceiling effect later
summary(IndexHappiness)
summary(IndexGratitude)
# Will break this down by group later on to get a better feel for the data. 

# B. Correlational Analyses

cor(IndexGratitude, IndexHappiness) # r = .56
# Highly correlated with one another. I will use a mixed effect model to look at this later. 

# Correlations within gratitude scale
cor(grateful, appreciative)
cor(appreciative, thankful)
cor(thankful, grateful)
G <- data.frame(grateful, appreciative, thankful)
CorGrate <- cor(G)
corrplot(CorGrate, method = "circle") # Extremely highly correlated with one another, even moreso than happiness below

# Happiness
cor(happy, content)
cor(content, pleasan)
cor(pleasan, happy) 
H <- data.frame(happy, content, pleasan)
CorHappy <- cor(H)
corrplot(CorHappy, method = "circle") # All relatively highly correlated with each other
# Content doesn't seem to fit as well. I am slightly less concerned about this because the major focus of this research is on gratitude, 
# with happiness as a control condition to show that the effect of gratitude on financial patience cannot be found for any positive emotion. 


# C. Basic Plotting
plot(group, IndexGratitude, ylab = "Gratitude (1 to 5)", xlab = "Condition")
# No serious outliers, ceiling effect for gratitude condition

plot(group, IndexHappiness, ylab = "Happiness (1 to 5)", xlab = "Condition")
# Could be one potential outlier here in the control condition, but will leave it in for now. 
# Looks to be some potential ceiling effects for happiness and gratitude, but overall looks relatively healthy. 

# Overall, Reflects what we saw from summary

# D. Advanced Plotting
# This section includes (1) XY Plots, (2) Violin Plots, and (3) 3D Scatterplots

#(1): XY Plots
xyplot(IndexHappiness ~ IndexGratitude) #Overall picture, see correlated
xyplot(IndexHappiness ~ IndexGratitude | group) # by group
xyplot(IndexHappiness ~ IndexGratitude, group=group,auto.key=list(space="right")) #all on same plot

# (2): Violin plots

vioplot(IndexGratitude,names="gratitude",ylim=c(0,5))
vioplot(IndexHappiness,names="happiness",ylim=c(0,5))
# Looks like a ceiling effect for both, but i'd predict it's driven by the specific treatment groups; Gratitude group has strong ceiling effect for gratitude; happiness group has strong ceiling effect for happiness
# Let's check this prediction below. 


# this time, by group

vioplot(IndexGratitude[condition=="control"],IndexGratitude[condition=="gratitude"], IndexGratitude[condition=="happiness"],col="yellow",
        names=c("control","gratitude", "happiness"),horizontal=T,border = "yellow")
title("Gratitude")
# confirms prediction for gratitude


vioplot(IndexHappiness[condition=="control"],IndexHappiness[condition=="gratitude"], IndexHappiness[condition=="happiness"],col="yellow",
        names=c("control","gratitude", "happiness"),horizontal=T,border = "yellow")
title("Happiness")
# again confirms prediction for happiness

# We can see in both that the control conditions are not at the ceiling for either happiness or gratitude; being driven by the treatment conditions, which might lead us to understate our effect on financial patience down the road

# (3): 3D Scatterplots
scatterplot3d(happy, content, pleasan)
scatterplot3d(grateful, appreciative, thankful)
# can also do it like this, although yields similar results
s3d <- scatterplot3d(happy ~ content + pleasan,angle=30,pch=16,color=rgb(0,0,0),grid=FALSE)
# Overall, somewhat helpful, shows higher correlation in gratitude 3d plot

## Part 3: Assumption Checks for Mixed Effect Model

# 1) Is our dependent variable metric? 
# Not quite- its a compilation of three ordinal responses between 1-5, so it's somewhere in between ordinal and metric. 
# That being said, it appears to represent metric better (e.g., can take the form of non whole numbers), although this is arguable. 
# We could use a generalized linear mixed effect model, but these seems excessively complex for a simple manipulation check. Will stick to regular mixed effect model in my analyses. 

# 2) Independence of observations within and across factors? 
# It's good that we have random assignment to emotion condition for independence.
# As seen below, happiness and gratitude dependent variable measures will be added as random effects to control for the pseudo-repeated measurement design. This is admittedly slightly artificial. 
# Additionally, the happiness and gratitude DVs are highly correlated (r = .56).


# 3) Normality?
??stat.desc
by(IndexGratitude, group, stat.desc, norm = TRUE)
# Fails only in the gratitude condition; makes some sense, as there is a strong ceiling effect. 
by(IndexHappiness, group, stat.desc, norm = TRUE)
# Fails in both emotion conditions, for similar reasons as gratitude. 

# We can use both parametric and nonparametric versions of the manipulation check to deal with this lack of normality. This is what I did in my midterm project. 
# Let's plot these by group again to get a better feel for our data. 

# Gratitude
op <- par(mfrow = c(3,1))
hist(IndexGratitude[group == "control"], main = "Histogram Control Group", xlab = "Gratitude")
hist(IndexGratitude[group == "gratitude"], main = "Histogram Gratitude Group", xlab = "Gratitude")
hist(IndexGratitude[group == "happiness"], main = "Histogram Happiness Group", xlab = "Gratitude")
par(op)

# Gratitude group looks slightly unhealthy, as we have many people responding with the maximum value. 
# This could be a problem with analyses as it could produce a ceiling effect. 
# That being said, similar emotion effects have been found in many previous publications 
# in the field of emotion and decision making, so we can continue with our analyses while
# also keeping this in the back of our mind in interpreting our results. 

# Happiness
op <- par(mfrow = c(3,1))
hist(IndexHappiness[group == "control"], main = "Histogram Control Group", xlab = "Happiness")
hist(IndexHappiness[group == "gratitude"], main = "Histogram Gratitude Group", xlab = "Happiness")
hist(IndexHappiness[group == "happiness"], main = "Histogram Happiness Group", xlab = "Happiness")
par(op)
#Similar pattern to gratitude in terms of ceiling effects in the happiness condition. 
# I believe the same logic applies here as discussed above so will tentatively continue, while keeping this effect in mind. 


# Let's also see the Q-Q plots for both gratitude and happiness

# Gratitude
op <- par(mfrow = c(1,3))
qqnorm(IndexGratitude[group == "control"], main = "Q-Q Plot Control")
qqline(IndexGratitude[group == "control"])
qqnorm(IndexGratitude[group == "gratitude"], main = "Q-Q Plot Gratitude")
qqline(IndexGratitude[group == "gratitude"])
qqnorm(IndexGratitude[group == "happiness"], main = "Q-Q Plot Happiness")
qqline(IndexGratitude[group == "happiness"])
par(op)
# Gratitude condition looks unhealthy like before, but this is driven by the ceiling effect previously discussed. 
# Other two look healthy.

# Happiness
op <- par(mfrow = c(1,3))
qqnorm(IndexHappiness[group == "control"], main = "Q-Q Plot Control")
qqline(IndexHappiness[group == "control"])
qqnorm(IndexHappiness[group == "gratitude"], main = "Q-Q Plot Gratitude")
qqline(IndexHappiness[group == "gratitude"])
qqnorm(IndexHappiness[group == "happiness"], main = "Q-Q Plot Happiness")
qqline(IndexHappiness[group == "happiness"])
par(op)
# Looks generally okay, not perfect. Again (sorry to repeat this over and over), it seems that ceiling effects based on the scale are to blame. 
# This could be an artifact of a 5-point Likert scale. Future research could consider a more sensitive scale. 

# Note: As in my midterm, you could use nonparametric tests to account for the lack of normality. I will focus on tools learned since the midterm: the mixed effect model. 

# Note: Although we don't have to worry as much about unbalanced designs with mixed effect models, we do have a fully balanced design in this experiment (25 participants per group)


##------------------- Section 2: Manipulation Check -------------------------

# This section will build up two (slightly artificial) mixed-effect models to check whether the manipulations were successful and emotion-specific.

# Will do a focused contrast between gratitude and happiness groups to make sure the inductions were emotion-specific. 

# Hyp 1: Participants in the gratitude condition will feel significantly more gratitude than those in the happiness condition, with happiness added as a random effect
# Hyp 2: Participants in the happiness condiiton will feel significantly more happiness than those in the gratitude condition, with gratitude added as a random effect

# From my midterm assignment, I know that participants in the gratitude condition felt signficiantly more gratitude than those in the happy/control combined condition; I know the same for happiness and the happiness condition vs the gratitude/control combined conditions.
# I'll use a mixed effect model to test whether the gratitude participants felt more gratitude than those in the happiness condition, entering happiness as a random effect.
# I'll do the same for the happiness condition (vs gratitude condition), entering gratitude as a random effect. 

# First, I'll subset my dataset to have only the gratitude and happiness groups
MixedEffectDataset <- subset(dataset, Condition > 1) # gets rid of control condition
head(MixedEffectDataset)
MixedEffectDataset$condition # Looks good: Note this is a bit confusing because condition is a factor, but Condition is numeric. 
# Now ready to do a contrast b/w gratitude and happiness groups for both emotions

# Gratitude

# Let's build up the model, first without the random effect
fit1 <- lm(MixedEffectDataset$IndexGratitude ~ MixedEffectDataset$condition)
summary(fit1)
# condition is a significant predictor of gratitude; participants in the gratitude condition felt significantly more gratitude than those in the happy condition (i.e., estimate is negative; p < .001)
# Note: This is a tiny p-value; gratitude induction is very strong, as seen in ceiling effect from data visualization
# Note RSE: .7419

# Now adding the random effect
fit2 <- lmer(MixedEffectDataset$IndexGratitude ~ MixedEffectDataset$condition + (1|MixedEffectDataset$IndexHappiness), REML = FALSE)
summary(fit2)
# Note: RSE down to .4305
# Similar estimate of -1.1 (in fit2) compared to -1.01 (in fit1), however, we've driven down the residual error by including the random effect. Seems to make sense to keep it in.

# Let's think about including random slopes
xyplot(MixedEffectDataset$IndexGratitude ~ MixedEffectDataset$condition|MixedEffectDataset$IndexHappiness, mainv = "Individual Regressions (Subjects)", panel=function(x, y){
  panel.xyplot(x, y)
  panel.lmline(x, y, lty=2)
}) #doesn't seem necessary to add random slope, all look generally the same.

# Happiness

# Let's again build up the model first without random effect, then with the random effect of gratitude
fit3 <- lm(MixedEffectDataset$IndexHappiness ~ MixedEffectDataset$condition)
summary(fit3)
# condition is a marginally significant predictor of happiness, p < .10; 
# Note: RSE = .6143

# Let's add in the random effect
fit4 <- lmer(MixedEffectDataset$IndexHappiness ~ MixedEffectDataset$condition + (1|MixedEffectDataset$IndexGratitude), REML = FALSE)
summary(fit4)
# Condition is now a significant predictor at the .05 alpha level, p < .05; participants in the happiness condition felt significantly more happiness than those in the gratitude condition
# RSE is down to .323, seems to make sense to keep the random effect in this model. Including random slopes would seem to be a bit too complex/needlessly complicating the model for a simple manipulation check. 

# At this point, I am convinced that the manipulation was successfull and emotion specific for both gratitude and happiness

##------------------- Section 3: Emotion Effect on Financial Patience -------------------------

### This section builds up multiple beta regressions to investigate the effect of gratitude (and happiness) on financial patience


# I am using a beta regression because my response variable (financial patience) is bounded between zero and one. This is one reason that the normality assumption would be violated for it. 
# That being said, I have zeros and ones in my data, so I will need to do the transformation suggested in Lecture 21 to squeeze my distribution a bit


mean(ExpDiscountRate) 
hist(ExpDiscountRate, main = "Discount Rate", xlab = "Discount Rate", breaks = 10) # Can see that it's far from normal, more reason to do beta regression

boxplot(ExpDiscountRate ~ condition, xlab = "Condition", ylab = "Discount Rate", main = "Box Plot Discount Rate") 
# Initial evidence that gratitude condition may be more financially patient. 

#First, need to transform my data so don't have zeros and ones:
BetaDiscountRate <- (((ExpDiscountRate)*(74)) + 0.5)/75
BetaDiscountRate # successful

boxplot(BetaDiscountRate ~ condition, xlab = "Condition", ylab = "Transformed Discount Rate", main = "Box Plot Transformed Discount Rate") 
hist(BetaDiscountRate, main = "Transformed Discount Rate", xlab = "Transformed Discount Rate", breaks = 10)

# Now, will do regression with focused contrast: gratitude group vs. control/happiness group


#First, need to reformat the conditions for our planned contrast
# Either yes (gratitude) or no (not gratitude)
class(condition)
levels(condition)
BetaCondition <-as.factor(rep(c("no", "yes", "no"), each = 25)) # matches ordering of conditions from dataset
levels(BetaCondition)
BetaCondition

# Now, can run focused contrast beta regression
fitBeta1 <- betareg(BetaDiscountRate ~ BetaCondition)       
summary(fitBeta1) 
# p < .06, so marginally significant effect of being in gratitude vs. other conditions on discount rate
partable <- cbind(coef = coef(fitBeta1), confint = confint(fitBeta1))
partable
round(exp(partable[1:3,]), 3)
# Interpretation of parameter: If someone is in the gratitude condition, 
# their odds of having a high discount rate (being very financially patient) increases by 1.648

AIC(fitBeta1)

# Let's also run a beta regression on gratitude and happiness indices themselves, rather than the groups
fitBeta2 <- betareg(BetaDiscountRate ~ IndexGratitude)
summary(fitBeta2)
# p < .09, again marginally significant
partable <- cbind(coef = coef(fitBeta2), confint = confint(fitBeta2))
partable
round(exp(partable[1:3,]), 3)
# Interpretation of parameter: A 1-unit increase in gratitude increases the odds of having a high discount rate by 1.204.

# Let's build up the model to include happiness
fitBeta3 <- betareg(BetaDiscountRate ~ IndexGratitude + IndexHappiness)
summary(fitBeta3)
# Now gratitude is significant at .05 alpha level, p < .03
partable <- cbind(coef = coef(fitBeta3), confint = confint(fitBeta3))
partable
round(exp(partable[1:3,]), 3)
# Interpretation of parameter: Controlling for happiness, a 1-unit increase in gratitude increases the odds of having a high discount rate by 1.341

AIC(fitBeta3)
AIC(fitBeta2) # Pretty similar overall, makes sense because emotion is explaining such a small amount of the variance in this model

# Upshot: Gratitude, but not happiness, appears to increase financial patience. 


##------------------- Section 4: Practicing Other Relevant Tools  -------------------------

# Note: I wanted to add some other tools since the midterm to practice them/get feedback.


#Some basic webscraping
ngdat <- ngram(c('gratitude','happiness', case_ins=TRUE),corpus='eng_2012',
               year_start=1800,year_end=2014,smoothing=4)
ngdat
webgrat <- ngdat$value[ngdat$variable=='gratitude'] 
webgrat

webhap <- ngdat$value[ngdat$variable=='happiness'] 
ylimits <- c(0,max(c(max(webgrat),max(webhap))))

names(ngdat)
plot(x=ngdat$Year[ngdat$variable=='gratitude'],y=webgrat,type="l",col="blue",
     lwd=2,ylim=ylimits,main="Gratitude and Happiness",ylab="Frequency",
     xlab="Year") 
points(x=ngdat$Year[ngdat$variable=='happiness'],y=webhap,type="l",col="red",lwd=2) 
text(1960,6*7.3^(-6),labels='happiness',col='red') # label Pope
text(1980,1*10.5^(-6),labels='gratitude',col='blue')
# Can see that both have declined dramatically since 1800, but that happiness is experiencing a small revival recently. Interesting to note that happiness isn't that much higher than gratitude. 

cval = cor(webgrat,webhap)
cval
# Wow, that's a crazily high correlation. It would be interesting to look at why they're so correlated in other research. 
# Let's add it to our graph:
text(1975,5*10^(-5),paste("r = ",as.character(round(cval,digits=2)),sep=""))


# Effect Size

# Look at gratitude group compared to control group to think about effect size
EffectSizeDataset <- subset(dataset, Condition < 3) # Get rid of happiness condition
cohen_d <- cohen.d(EffectSizeDataset$ExpDiscountRate ~ EffectSizeDataset$Condition)
cohen_d
# d = .515, which is a medium effect size

# We can now look at power and work backward to what we would have wanted our sample size to be from here.
# This is a bit off, as our actual model uses a planned contrast between gratitude and the combination of the happy/control groups, so it would be a bit weird to do this outside of this assignment

## Power and sample size Calculation
pwr.t.test(d = 0.5, power = 0.8, alternative = "greater") 
# Says need a sample size of around 50 per group; had only 25 per group in sample, which makes sense that still found significant results because used a planned contrast rather than pure t-test


detach(dataset)

##------------------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------------------

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

# can I improve the model?
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

# what if I remove non-significant metrics?
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