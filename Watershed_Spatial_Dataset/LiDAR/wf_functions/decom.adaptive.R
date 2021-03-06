decom.adaptive<-function(x,smooth=TRUE,thres=0.22,width=3){
  y0<-as.numeric(x)
  index<-y0[1]
  y<-y0[-1]
  y[y==0]<-NA
  ###when for direct decomposition
  y<-y-min(y,na.rm = T)+1
  if (smooth==TRUE) y<-runmean(y,width,"C")##"fast" here cannot handle the NA in the middle
  peakrecord<-lpeak(y,3)#show TRUE and FALSE
  peaknumber<-which(peakrecord == T)#show true's position, namely time in this case
  #peaknumber,it show the peaks' corresponding time
  imax<-max(y,na.rm=T)
  ind<-y[peaknumber]>thres*imax      #####################you need to change threshold##########################################
  realind<-peaknumber[ind]#collect time
  newpeak<-y[realind]  #collect intensity
  z<-length(realind)

  #then we fliter peak we have in the waveform
  #you must define newpeak as a list or a vector(one demision),otherwise it's just a value
  #I just assume that intensity is larger than 45 can be seen as a peak, this can be changed

  #####if the peak location is too close, remove it just keep one???????
  #not sure we really need this step

  ##################################initilize parameters
  ##use adptive Gaussian
  ##first use gaussian to estimate the values
  tre<-decom(x)
  if (is.null(tre[[1]])){

    agu<-0.9*realind
    agi<-newpeak*2/3
    agsd<-realind[1]/6
    if (z>1){
      agsd[2:z]<-diff(realind)/5
    }
    ari<- rep (2,z)

    init0 <- agennls(agi, agu, agsd, ari)
    sv<-as.numeric(init0$start);
    ad1<-sv*c(rep(0.4,z),rep(0.35,z),rep(0.35,z),rep(0.3,z))
    #ad1<-c(rep(60,z),rep(12,z),rep(8,z),rep(0.5,z))

    up<-sv+ad1
    low<-sv-ad1
  } else if (is.na(tre[[1]])) {
    agu<-0.9*realind
    agi<-newpeak*2/3
    agsd<-realind[1]/6
    if (z>1){
      agsd[2:z]<-diff(realind)/5
    }
    ari<- rep (2,z)

    init0 <- agennls(agi, agu, agsd, ari)
    sv<-as.numeric(init0$start);
    ad1<-sv*c(rep(0.3,z),rep(0.3,z),rep(0.3,z),rep(0.25,z))
    #ad1<-c(rep(60,z),rep(12,z),rep(8,z),rep(0.5,z))

    up<-sv+ad1
    low<-sv-ad1
  } else {
    pars<-tre[[3]]

    agi<-pars[,2]
    agu<- pars[,3]
    agsd<-pars[,4]

    ari<- rep(2,z)  ###for adaptive Gaussian function

    init0 <- agennls(agi, agu, agsd, ari)
    sv<-as.numeric(init0$start);
    ad1<-sv*c(rep(0.2,z),rep(0.2,z),rep(0.25,z),rep(0.25,z))

    up<-sv+ad1
    low<-sv-ad1
  }

  #init$formula
  #init$start
  df<-data.frame(x=seq_along(y),y)
  log<-tryCatch(fit<-nlsLM(init0$formula,data=df,start=init0$start,algorithm='LM',lower=low,upper=up,control=nls.lm.control(factor=100,maxiter=1024,
                                                                                                         ftol = .Machine$double.eps, ptol = .Machine$double.eps),na.action=na.omit),error=function(e) NULL)#this maybe better
  ###then you need to determine if this nls is sucessful or not?
  if (!is.null(log)){
    result=summary(fit)$parameters
    pn<-sum(result[,1]>0)
    rownum<-nrow(result);npeak<-rownum/4
    #record the shot number of not good fit
    rightfit<-NA;ga<-matrix(NA,rownum,5);#pmi<-matrix(NA,npeak,9)
    ga<-cbind(index,result)
    pmi<-NULL
    if (pn==rownum){
      rightfit<-index

      ####directly get the parameters
      ###make a matrix
      pm<-matrix(NA,npeak,8)
      pm[,1]<-result[1:npeak,1];pm[,5]<-result[1:npeak,2]
      s2<-npeak+1;e2<-2*npeak
      pm[,2]<-result[s2:e2,1];pm[,6]<-result[s2:e2,2]
      s3<-2*npeak+1;e3<-3*npeak
      pm[,3]<-result[s3:e3,1];pm[,7]<-result[s3:e3,2]
      s4<-3*npeak+1;e4<-4*npeak
      pm[,4]<-result[s4:e4,1];pm[,8]<-result[s4:e4,2]
      pmi<-cbind(index,pm)
      colnames(pmi) = c("index","A","u","sigma","r","A_se","u_se","sigma_se","r_se")

    }
    return (list(rightfit,ga,pmi))
  }
}