#instala os pacotes necess?rios para execu??o do programa
if(!require(forecast)) install.packages("forecast", dep=T); require(forecast)
if(!require(tseries)) install.packages("tseries", dep=T); require(tseries)
if(!require(plyr)) install.packages("plyr", dep=T); require(plyr)
if(!require(lubridate)) install.packages("lubridate", dep=T); require(lubridate)
if(!require(boot)) install.packages("boot", dep=T); require(boot)

# Mapeia o diretorio e carrega as bases de dados
setwd("/home/igorstemler/monet_sampling_benchmark/src")
load("../data/bd_random.RData")
pop <- read.csv("../data/BR_pop.csv")
load("../data/bd_random.strat.RData")

# images' directory 
img.dir <- "../paper/img/"

# data directory
data.dir <- "../data/"


# Deflacionar os valores pelo IPCA anual, mes base Janeiro.
pop$payment_date <- as.Date.character(as.character(pop$payment_date),"%Y-%m-%d")
bd_random$payment_date <- as.Date.character(as.character(bd_random$payment_date),"%Y-%m-%d")
bd_random.estr$payment_date <- as.Date.character(as.character(bd_random.estr$payment_date),"%Y-%m-%d")

pop$mean.def <-ifelse(year(pop$payment_date) == 2017, pop$mean * 1,
       ifelse(year(pop$payment_date) == 2016, pop$mean * 1.005354,
              ifelse(year(pop$payment_date) == 2015, pop$mean * 1.16633,
                     ifelse(year(pop$payment_date) == 2014, pop$mean * 1.24958,
                            ifelse(year(pop$payment_date) == 2013, pop$mean * 1.31937,
                                   ifelse(year(pop$payment_date) == 2012, pop$mean * 1.40057,
                                          ifelse(year(pop$payment_date) == 2011, pop$mean * 1.48766,NA)))))))

plot(pop[,c("payment_date","mean")],ylim=c(90,300))
lines(pop[,c("payment_date","mean.def")],col="red")

############### RANDOM SAMPLE 1.347 ################################################
# Cria a base de dados inicial onde serao inseridas as medias obtidas pelo metodo bootstrap.
b <- aggregate(bd_random$value, FUN=mean, by=list(bd_random$payment_date))
colnames(b) <- c("payment_date","mean.sample")
n <- nrow(bd_random)
m <- 1000

# Faz as iteracoes para coletar as medias de cada ao e mes.
for (i in 1:m){
  set.seed(6885*i)
  unifnum = sample(1:n,n,replace = T)
  mean.payment = aggregate(bd_random[unifnum,"value"], FUN=mean, by=list(bd_random[unifnum,"payment_date"]))
  colnames(mean.payment) <- c("payment_date",paste0("x",i))
  b <- merge(b, mean.payment, by = "payment_date")
}

# Calcula a media das medias geradas, o desvio padrao amostral e o intervalo de confianca.
b$mean.amostra <- apply(b[,3:ncol(b)],1,mean)
b$erro.padrao <- NA
for (i in 1:nrow(b)){
  b$erro.padrao[i] <-sqrt(sum((b[i,3:(m+2)] - b$mean.amostra[i])^2/(m-1)))
}
conf <- 1.96
b$ic.inf <- b$mean.amostra - conf*b$erro.padrao
b$ic.sup <- b$mean.amostra + conf*b$erro.padrao
b$mean.mov <- b$mean.amostra

# Serie ajustada pela media do valor do mes e dos meses adjacentes.
for (i in 3:(nrow(b)-2)){
  b$mean.mov[i] <- mean(b$mean.amostra[(i-2):(i+2)])
}

# Junta a base populacional com a amostral
b <- merge(b, pop[,c("payment_date","mean")], by="payment_date")
b$col <- ifelse(b$mean >= b$ic.inf & b$mean <= b$ic.sup,"darkblue","red")
table(b$col)

# Salva o grafico de comparacao da serie temporal populacional e amostral.
pdf(paste0(img.dir, "_Time_series_pop_random_sample_1347.pdf"))
plot(b[c("payment_date","mean.amostra")],col="green",type="l",lwd=0.7,axes = T, xlab="Year", ylab="Mean value of Bolsa Familia",ylim=c(50,300))
lines(b[c("payment_date","mean")],col="darkblue",lwd=3)
#lines(b[c("payment_date","mean.mov")], col="yellow", lwd=2)
lines(b[c("payment_date","ic.inf")], col="red",lty=2)
lines(b[c("payment_date","ic.sup")], col="red",lty=2)
legend("topleft",legend = c("Population","Sample","Confidence interval"),col = c("darkblue","green","red"),lty = c(1,1,2),bty = "n")
dev.off()

# Verifica a consistencia da amostra em relacao ao resultado da media total. 
mean.sample <- function(data, indices) {
  d <- data[indices,] 
  return(mean(d$value,na.rm=T))
} 
boot.mean <- boot(data=bd_random, statistic=mean.sample, R=1000)
boot.mean

# Grafico do resultado do bootstrap
plot(boot.mean)

# get 95% confidence interval 
boot.ci(boot.mean,type = "norm")

# Media populacional = 148.2 intervalo de (143.8, 152,7) pelo tamanho de amostra escolhido, ou seja, erro de 3% e 95% de confianca
# Media bootstrap = 148.66 intervalo de confianca de (144.1, 153.0).



############### RANDOM SAMPLE 392.080 ################################################
# Cria a base de dados inicial representativa por UF onde serao inseridas as medias obtidas pelo metodo bootstrap.
b.estr <- aggregate(bd_random.estr$value, FUN=mean, by=list(bd_random.estr$payment_date))
colnames(b.estr) <- c("payment_date","mean.sample")
n <- nrow(bd_random.estr)
m <- 100

# Faz as iteracoes para coletar as medias de cada ao e mes.
for (i in 1:m){
  set.seed(6885*i)
  unifnum = sample(1:n,n,replace = T)
  mean.payment = aggregate(bd_random.estr[unifnum,"value"], FUN=mean, by=list(bd_random.estr[unifnum,"payment_date"]))
  colnames(mean.payment) <- c("payment_date",paste0("x",i))
  b.estr <- merge(b.estr, mean.payment, by = "payment_date")
}

# Calcula a media das medias geradas, o desvio padrao amostral e o intervalo de confianca.
b.estr$mean.amostra <- apply(b.estr[,3:(m+2)],1,mean)
b.estr$erro.padrao <- NA
for (i in 1:nrow(b.estr)){
  b.estr$erro.padrao[i] <-sqrt(sum((b.estr[i,3:(m+2)] - b.estr$mean.amostra[i])^2/(m-1)))
}
conf <- 1.96
b.estr$ic.inf <- b.estr$mean.amostra - conf*b.estr$erro.padrao
b.estr$ic.sup <- b.estr$mean.amostra + conf*b.estr$erro.padrao
b.estr <- merge(b.estr, pop[,c("payment_date","mean")], by="payment_date")
b.estr$col <- ifelse(b.estr$mean >= b.estr$ic.inf & b.estr$mean <= b.estr$ic.sup,"darkblue","red")
table(b.estr$col)

# Salva o grafico de comparacao da serie temporal populacional e amostral.
pdf(paste0(img.dir, "_Time_series_pop_random_sample_392080.pdf"))
plot(b.estr[c("payment_date","mean")],col=b.estr$col,type="o",lwd=1,axes = T,cex=0.7, xlab="Year", ylab="Mean value of Bolsa Familia")
#axis(1,pretty(seq(as.Date("2011-01-01"), by="1 month", len=74)))
#axis(2,pretty(b.estr$mean),pos=0)
lines(b.estr[c("payment_date","mean.amostra")],col="green",lwd=2)
lines(b.estr[c("payment_date","ic.inf")], col="red",lty=2)
lines(b.estr[c("payment_date","ic.sup")], col="red",lty=2)
legend("topleft",legend = c("Population","Sample","Confidence interval"),col = c("Darkblue","green","red"),lty = c(1,1,2),bty = "n")
dev.off()



tab <- data.frame(random=data.frame(table(bd_random$state)),
           random.estrt=data.frame(table(bd_random.estr$state)))
write.csv(tab,"../data/Amostras por UF.csv")


#End
