################################################################
# TEST CODE

library(data.table)
library(haven)
library(surveysd)
library(simPop)

dat <- fread("/mnt/meth/Gussenbauer/surveysd/udb_short.csv")
dat <- dat[RB020!="CZ"]
colnames(dat) <- tolower(colnames(dat))
dat[,rb050:=as.numeric(gsub(",",".",rb050))]
dat[,db030_neu:=paste(rb020,db030,sep="_")]

#dat_boot <- draw.bootstrap(dat,REP=10,hid="db030_neu",weights="rb050",strata="db040",
#                          year="rb010",totals=NULL,boot.names=NULL)

dat_boot <- draw.bootstrap(dat,REP=3,hid="db030",weights="rb050",strata=c("db040"),
                           year="rb010",country="rb020",totals=NULL,boot.names=NULL)


dat_boot <- dat_boot[!is.na(hx080)]
dat_boot[,hx080:=factor(hx080)]
dat_boot_test <- copy(dat_boot)

t <- Sys.time()
dat_boot_calib <- recalib(dat=copy(dat_boot),hid="db030",weights="rb050",
                          year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080"),conversion_messages=TRUE)
Sys.time()-t

str(dat_boot_calib)

microbenchmark(HID_FACTOR=recalib(dat=copy(dat_boot),hid="db030",weights="rb050",
                       year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080"),conversion_messages=TRUE),
               HID_NOFACTOR=recalib(dat=copy(dat_boot),hid="db030",weights="rb050",
                       year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080"),conversion_messages=TRUE,hidf_factor = FALSE),times=20)



dat_boot_test[,rb090:=factor(rb090)]
dat_boot_test[,db040:=factor(db040)]
dat_boot_test[,rb010:=factor(rb010)]
t <- Sys.time()
dat_boot_calib <- recalib(dat=copy(dat_boot_test),hid="db030",weights="rb050",
                          year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080"),hidf_factor = FALSE,conversion_messages=TRUE)
Sys.time()-t

microbenchmark(HID_FACTOR=recalib(dat=copy(dat_boot_test),hid="db030",weights="rb050",
                                  year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080")),
               HID_NOFACTOR=recalib(dat=copy(dat_boot_test),hid="db030",weights="rb050",
                                    year="rb010",country="rb020",b.rep=paste0("w",1),conP.var=c("rb090"),conH.var = c("db040","hx080"),hidf_factor = FALSE))



dat_boot_calib

erg <- calc.stError(dat=copy(dat_boot_calib),weights="rb050",year="rb010",b.weights=paste0("w",1:110),
                    var="hx080",cross_var=list(c("db040","db100")),year.diff=c("2016-2008"),
                    p=c(.01,.05,.1,.9,.95,.99))

erg

erg$smallGroups


year.diff=c("84984-51515","36235-2525","134525-2525")


a <- data.table(1:10,LETTERS[1:10])
b <- data.table(20:19,LETTERS[1:10])
b[,V2:=factor(V2)]
a[,V1:=factor(V1)]
merge(b,a,by="V2")
b[,V2:=as.numeric(factor(V2))]

b[,V2:=levels(V2)[V2]]

a <- data.table(1:10,LETTERS[1:10])
b <- data.table(0:9,LETTERS[11:20])
b[,V1:=factor(V1)]
b[,V1:=as.numeric(as.character(V1))]

merge(b,a,by="V1")

# bsp1:
a <- data.table(1:10,LETTERS[1:10])
b <- data.table(20:19,LETTERS[1:10])
b[,V2:=factor(V2)]
setkey(a, V2); setkey(b, V2)
b[a]

# bsp2
a <- data.table(1:10,LETTERS[1:10])
b <- data.table(20:19,LETTERS[1:10])
b[,V1:=factor(V1)]
setkey(a, V1); setkey(b, V1)
b[a]

#####################################################
# TEST INPUT CHECKING
a <- list(1:1000)
recalib(dat=copy(dat_boot),hid="db030",weights=c("rb050"),
        year="rb010",country="rb020",b.rep=paste0("w",1:10),conP.var=c("rb090"),conH.var = c("db040","hx080"))



# TEST C++ code
library(Rcpp)
sourceCpp("src/helpersC.cpp")

comp <- rep(FALSE,10000)
for(i in 1:10000){
  x <- sample(c(1,0,NA_real_),200,prob=c(.45,.45,.1),replace=TRUE)
  w <- sample(30:400,200,replace=TRUE)

  r_res <- weightedRatio(x,w)
  c_res <- weightedRatioC(x,w)

  comp[i] <- abs(r_res-c_res)<1e-10
}

comp <- rep(FALSE,10000)
for(i in 1:10000){
  x <- sample(c(1,0,NA_real_),200,prob=c(.45,.45,.1),replace=TRUE)
  w <- sample(30:400,200,replace=TRUE)

  r_res <- weightedSum(x,w)
  c_res <- weightedSumC(x,w)

  comp[i] <- abs(r_res-c_res)<1e-10
}



#########################################
# teste clustering
#

library(data.table)
library(haven)
library(surveysd)
library(simPop)
library(survey)

dat <- fread("/mnt/obdatenaustausch/NETSILC3/udb_short_new.csv")
dat[,RB050:=gsub(",","\\.",RB050)]
dat[,RB050:=as.numeric(RB050)]
# DB060 CLUSTER
# DB050 STRATA
# CLUSTER WERDEN IN STRATA GEZOGEN

# check was mit lonely PSU passiert

dat[,.N,by=RB020]

dat_es <- dat[RB020=="ES"]
dat_es[is.na(db050)]
dat_es[is.na(DB060)]

dat_es[,fpc1:=length(unique(DB060))/.05,by=list(db050,RB010)]
dat_es[,fpc2:=sum(RB050[!duplicated(db030)]),by=list(DB060,db050,RB010)]

set.seed(1234)
dat_boot_1 <- draw.bootstrap(dat=copy(dat_es),REP=100,hid="db030",weights="RB050",strata="db050",cluster=c("DB060"),
                           year="RB010",totals=c("fpc1","fpc2"),boot.names=NULL)
set.seed(1234)
dat_boot_2 <- draw.bootstrap(dat=copy(dat_es),REP=100,hid="db030",weights="RB050",strata="db050",cluster=c("DB060"),
                           year="RB010",boot.names=NULL)


dat_boot <- dat_boot[!is.na(HX080)]
dat_boot[,hx080:=factor(HX080)]

dat_boot_calib <- recalib(dat=copy(dat_boot),hid="db030",weights="RB050",
                          year="RB010",b.rep=paste0("w",1:1000),conP.var=c("RB090"),conH.var = c("DB040"))

erg <- calc.stError(dat=copy(dat_boot_calib),fun="weightedRatioNat",weights="RB050",year="RB010",b.weights=paste0("w",1:250),
                    var="HX080",cross_var=list(c("DB040","DB100")),year.diff=c("2016-2008"),
                    p=c(.01,.05,.1,.9,.95,.99))


set.seed(1234)
dat_boot_1 <- draw.bootstrap(dat=copy(dat_es),REP=100,hid="db030",weights="RB050",strata="db050",cluster=c("DB060"),
                             year="RB010",totals=c("fpc1","fpc2"),boot.names=NULL)
set.seed(1234)
dat_boot_2 <- draw.bootstrap(dat=copy(dat_es),REP=100,hid="db030",weights="RB050",strata="db050",cluster=c("DB060"),
                             year="RB010",boot.names=NULL)




# TESTE ipu2
library(data.table)
library(surveysd)
dat <- fread("/mnt/obdatenaustausch/NETSILC3/udb_short_new.csv")
dat[,RB050:=gsub(",","\\.",RB050)]
dat[,RB050:=as.numeric(RB050)]

dat_es <- dat[RB020=="ES"]
dat_es[,.(RB010,RB030,DB040,arose,hsize,HX040,db050)]

dat_es[,totals1:=round(sum(RB050[!duplicated(db030)])/400),by=list(RB010,db050)]
dat_es[,totals2:=400]

# define stratified 1-Stage cluster sample
set.seed(1234)
dat_boot <- draw.bootstrap(dat=copy(dat_es),REP=150,hid="db030",weights="RB050",strata="DB040",cluster="DB060",
                           year="RB010",totals=c("totals1","totals2"))

dat_boot_calib <- recalib(dat=copy(dat_boot),hid="db030",weights="RB050",
                          year="RB010",b.rep=paste0("w",1:150),conP.var=c("RB090"),conH.var = c("DB040","HX080"))
save(dat_boot_calib, file="/mnt/meth/Gussenbauer/surveysd/TEST.RData")
load("/mnt/meth/Gussenbauer/surveysd/TEST.RData")
erg <- calc.stError(dat=copy(dat_boot_calib),weights="RB050",year="RB010",b.weights=paste0("w",1:150),
                    var="HX080",cross_var=list("DB040","RB090","hsize",c("DB040","hsize"),c("DB040","RB090")),year.diff=c("2014-2008"),
                    p=c(.01,.05,.1,.9,.95,.99))

# cluster(DB060) in strata(db050) bestehen aus ca 400 Einheiten
# Anzahl cluster in strate = HH_STRATA / 400


library(ggplot2)
library(data.table)
library(gridExtra)
library(grid)
# prototype summary function
erg$Estimates

plot.dat <- erg$Estimates[grepl("^[[:digit:]]+$",RB010)]
plot.dat <- merge(plot.dat,erg$smallGroups,all.x=TRUE)
setkeyv(erg$cvHigh,c("RB010","DB040","RB090","hsize"))
plot.dat <- erg$cvHigh[plot.dat]

plot.dat[!is.na(N)&HX080==FALSE,res_type:="SmallGroup"]
plot.dat[!is.na(N)&HX080==TRUE,res_type:="SmallGroup+cvHigh"]
plot.dat[is.na(val_HX080),res_type:="Missing"]
plot.dat[HX080==TRUE&is.na(res_type),res_type:="cvHigh"]
plot.dat[is.na(res_type),res_type:="OK"]
plot.dat[,res_type:=factor(res_type,levels)]

plot.dat2 <- erg$Estimates[grepl("_",RB010)]
plot.dat2 <- merge(plot.dat2,erg$smallGroups,all.x=TRUE)
setkeyv(erg$cvHigh,c("RB010","DB040","RB090","hsize"))
plot.dat2 <- erg$cvHigh[plot.dat2]

plot.dat2[!is.na(N)&HX080==FALSE,res_type:="SmallGroup"]
plot.dat2[!is.na(N)&HX080==TRUE,res_type:="SmallGroup+cvHigh"]
plot.dat2[is.na(val_HX080),res_type:="Missing"]
plot.dat2[HX080==TRUE&is.na(res_type),res_type:="cvHigh"]
plot.dat2[is.na(res_type),res_type:="OK"]

fill.values1 <- plot.dat[,unique(res_type)]
fill.values2 <- plot.dat2[,unique(res_type)]

poss.values <- c("Missing","cvHigh","SmallGroup+cvHigh","SmallGroup","OK")
poss.color <- c("grey","orangered3","maroon","dodgerblue1","green4",)



fill.color1 <- poss.color[poss.values%in%fill.values1]
fill.values1 <- poss.values[poss.values%in%fill.values1]

p1 <- ggplot(plot.dat,aes(RB010,fill=res_type))+
  geom_bar()+
  theme(legend.title = element_blank())+xlab("")+ylab("Count")+
  scale_fill_manual(breaks = fill.values1,
                    values=fill.color1)

fill.color2 <- poss.color[poss.values%in%fill.values2]
fill.values2 <- poss.values[poss.values%in%fill.values2]

p2 <-  ggplot(plot.dat2,aes(RB010,fill=res_type))+
  geom_bar()+
  theme(legend.title = element_blank())+xlab("")+ylab("Count")+
  scale_fill_manual(breaks = fill.values2,
                    values=fill.color2)

plots <- list(p1,p2)
if(length(fill.values1)<length(fill.values2)){
  g <- ggplotGrob(plots[[2]] + theme(legend.position="bottom"))$grobs
}else{
  g <- ggplotGrob(plots[[1]] + theme(legend.position="bottom"))$grobs
}

legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
lheight <- sum(legend$height)
grid.arrange(
  do.call(arrangeGrob, lapply(plots, function(x)
    x + theme(legend.position="none"))),
  legend,
  ncol = 1,
  heights = unit.c(unit(1, "npc") - lheight, lheight))





str(plot.dat)
str(erg$cvHigh)


a <- data.table(LETTERS[1:5],c(1,2,3,NA,NA),letters[1:5])
b <- data.table(LETTERS[1:5],c(1,2,3,NA,NA))
merge(a,b)


data.table::merge(plot.dat[RB010==2008&is.na(db050)],erg$cvHigh[RB010==2008&is.na(db050)])
setkeyv(plot.dat,c("RB010","db050","RB090"))
plot.dat[erg$cvHigh]