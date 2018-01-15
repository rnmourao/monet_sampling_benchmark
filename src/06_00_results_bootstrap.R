#instala os pacotes necessessários para execuão do programa
if(!require(forecast)) install.packages("forecast", dep=T); require(forecast)
if(!require(tseries)) install.packages("tseries", dep=T); require(tseries)
if(!require(plyr)) install.packages("plyr", dep=T); require(plyr)
if(!require(dplyr)) install.packages("dplyr", dep=T); require(dplyr)
if(!require(tidyr)) install.packages("tidyr", dep=T); require(tidyr)
if(!require(lubridate)) install.packages("lubridate", dep=T); require(lubridate)
if(!require(boot)) install.packages("boot", dep=T); require(boot)
if(!require(TTR)) install.packages("TTR", dep=T); require(TTR)

# Mapeia o diretorio e carrega as bases de dados
setwd("/home/igorstemler/monet_sampling_benchmark-master/src")
core <- "single_core"
load(paste0("../data/",core,"/bd_random.RData"))
load(paste0("../data/",core,"/bd_random.strat.RData"))
pop <- read.csv(paste0("../data/",core,"/BR_pop.csv"), stringsAsFactors = F)
pop.uf <- read.table("../data/avg_state_date.txt",sep="|",skip=4, stringsAsFactors = F)
pop.uf <- pop.uf[,2:4]  
colnames(pop.uf) <- c("state","p_date","mean")
pop.uf$state <- trimws(pop.uf$state)
pop.uf$p_date <- trimws(pop.uf$p_date)

# Diretório de imagens 
img.dir <- "../paper/img/"

# Diretório dos dados
data.dir <- paste0("../data/",core)

# Transformar em data.
pop$p_date <- as.Date.character(as.character(pop$p_date),"%Y-%m-%d")
pop.uf$p_date <- as.Date.character(as.character(pop.uf$p_date),"%Y-%m-%d")
bd_random$p_date <- as.Date.character(as.character(bd_random$p_date),"%Y-%m-%d")
bd_random.estr$p_date <- as.Date.character(as.character(bd_random.estr$p_date),"%Y-%m-%d")

# Adiciona os dados do saldo de cadastrados na base de dados da populacao
pop1 <- read.table(paste0("../data/",core,"/count-unique.txt"), sep="|", header = F, stringsAsFactors = F,skip=3)
pop1$freshout <- c(0,pop1$V4[1:(nrow(pop1)-1)])
pop1$saldo <- pop1[,3] + pop1$freshout
pop1$pop.saldo <- cumsum(pop1$saldo) / c(pop1$saldo[1],cumsum(pop1$saldo)[1:(nrow(pop1)-1)])-1
pop1$p_date <- as.Date.character(pop1$V2, "%Y-%m-%d")
pop <- merge(pop,pop1[,c("p_date","pop.saldo")],by="p_date")
rm(pop1)

############### Amostra simples para a população - 1.347 ################################################
# Cria a base de dados inicial onde serao inseridas as medias obtidas pelo metodo bootstrap.
b <- aggregate(bd_random$value, FUN=mean, by=list(bd_random$p_date))
colnames(b) <- c("p_date","mean.sample")
n <- nrow(bd_random)
m <- 1000

# Faz as iteracoes para coletar as medias de cada ao e mes.
for (i in 1:m){
  set.seed(6885*i)
  unifnum = sample(1:n,n,replace = T)
  mean.payment = aggregate(bd_random[unifnum,"value"], FUN=mean, by=list(bd_random[unifnum,"p_date"]))
  colnames(mean.payment) <- c("p_date",paste0("x",i))
  b <- merge(b, mean.payment, by = "p_date")
}

# Calcula a media das medias geradas, o erro padrão amostral e o intervalo de confianca.
b$mean.amostra <- apply(b[,3:ncol(b)],1,mean)
b$erro.padrao <- NA
for (i in 1:nrow(b)){
  b$erro.padrao[i] <-sqrt(sum((b[i,3:(m+2)] - b$mean.amostra[i])^2/(m-1)))
}
conf <- 1.96
b$ic.inf <- b$mean.amostra - conf*b$erro.padrao
b$ic.sup <- b$mean.amostra + conf*b$erro.padrao

# Junta a base populacional com a amostral
b <- merge(b, pop[,c("p_date","mean")], by="p_date")
b$col <- ifelse(b$mean >= b$ic.inf & b$mean <= b$ic.sup,"darkblue","red")

# Número de pontos dentro do intervalo de confiança (darkblue)
table(b$col)

# Salva o grafico de comparacao da serie temporal populacional e amostral.
pdf(paste0(img.dir, "_Time_series_pop_random_sample_1347.pdf"))
plot(b[c("p_date","mean.amostra")],col="green",type="l",lwd=0.7,axes = T, xlab="Ano", ylab="Média de valores do Bolsa Familia",ylim=c(50,300))
lines(b[c("p_date","mean")],col="darkblue",lwd=3)
lines(b[c("p_date","ic.inf")], col="red",lty=2)
lines(b[c("p_date","ic.sup")], col="red",lty=2)
legend("topleft",legend = c("População","Amostra","Intervalo de confiança"),col = c("darkblue","green","red"),lty = c(1,1,2),bty = "n")
dev.off()

# Verifica a consistencia da amostra em relacao ao resultado da media total. 
mean.sample <- function(data, indices) {
  d <- data[indices,] 
  return(mean(d$value,na.rm=T))
} 
boot.mean <- boot(data=bd_random, statistic=mean.sample, R=1000)
boot.mean

# Grafico do resultado do bootstrap
pdf(paste0(img.dir, "bootstrap_random_sample_1347.pdf"))
  plot(boot.mean)
dev.off()

# Intervalo de confiança de 95% 
sink(paste0(data.dir, "ci_bootstrap_random_sample_1347.txt"))
  boot.ci(boot.mean,type = "norm")
sink()

# Media populacional = 148.2 intervalo de (143.8, 152,7) pelo tamanho de amostra escolhido, ou seja, erro de 3% e 95% de confiança
# Media bootstrap = 149.5 intervalo de confianca de (145, 154.1).


############### Amostra simples para a população por UF - 392.080 ################################################
# Cria a base de dados inicial representativa por UF onde serao inseridas as medias obtidas pelo metodo bootstrap.
m.estr <- aggregate(bd_random.estr$value, FUN=mean,na.rm=T, by=list(bd_random.estr$p_date))
colnames(m.estr) <- c("p_date","mean.sample")
s.estr <- aggregate(bd_random.estr[,c("newcomer","freshout")], FUN=sum, by=list(bd_random.estr$p_date))
s.estr$freshout <- c(0,s.estr$freshout[1:(nrow(s.estr)-1)])
colnames(s.estr) <- c("p_date","newcomer","freshout")
s.estr$saldo <- s.estr$newcomer + s.estr$freshout
s.estr$p.saldo <- cumsum(s.estr$saldo) / c(s.estr$saldo[1],cumsum(s.estr$saldo)[1:(nrow(s.estr)-1)])-1
s.estr <- s.estr[,c("p_date","p.saldo")]
m.estr.uf <- aggregate(bd_random.estr$value, FUN=mean,na.rm=T, by=list(paste0(bd_random.estr$state,bd_random.estr$p_date)))
colnames(m.estr.uf) <- c("chave","mean.sample")
n <- nrow(bd_random.estr)
m <- 100

# Faz as iteracoes para coletar as medias de cada ao e mes.
for (i in 1:m){
  set.seed(6885*i)
  unifnum = sample(1:n,n,replace = T)
  mean.payment = aggregate(bd_random.estr$value[unifnum], FUN=mean,na.rm=T, by=list(bd_random.estr$p_date[unifnum]))
  colnames(mean.payment) <- c("p_date",paste0("x",i))
  m.estr <- merge(m.estr, mean.payment, by = "p_date")
  mean.saldo <- aggregate(bd_random.estr[unifnum,c("newcomer","freshout")], FUN=sum, by=list(bd_random.estr$p_date[unifnum]))
  mean.saldo$freshout <- c(0,mean.saldo$freshout[1:(nrow(mean.saldo)-1)])
  colnames(mean.saldo) <- c("p_date","newcomer","freshout")
  mean.saldo$saldo <- mean.saldo$newcomer + mean.saldo$freshout
  mean.saldo$p.saldo <- cumsum(mean.saldo$saldo) / c(mean.saldo$saldo[1],cumsum(mean.saldo$saldo)[1:(nrow(mean.saldo)-1)])-1
  mean.saldo <- mean.saldo[,c("p_date","p.saldo")]
  colnames(mean.saldo) <- c("p_date",paste0("x",i))
  s.estr <- merge(s.estr, mean.saldo, by = "p_date")
  mean.payment.uf <- aggregate(bd_random.estr$value[unifnum], FUN=mean,na.rm=T, by=list(paste0(bd_random.estr$state[unifnum],bd_random.estr$p_date[unifnum])))
  colnames(mean.payment.uf) <- c("chave",paste0("x",i))
  m.estr.uf <- merge(m.estr.uf, mean.payment.uf, by = "chave")
  }


############# Valor médio ##########################################
# Calcula a media das medias geradas, o desvio padrao amostral e o intervalo de confianca.
m.estr$mean.amostra <- apply(m.estr[,3:(m+2)],1,mean)
m.estr$erro.padrao <- NA
for (i in 1:nrow(m.estr)){
  m.estr$erro.padrao[i] <-sqrt(sum((m.estr[i,3:(m+2)] - m.estr$mean.amostra[i])^2/(m-1)))
}
conf <- 1.96
m.estr$ic.inf <- m.estr$mean.amostra - conf*m.estr$erro.padrao
m.estr$ic.sup <- m.estr$mean.amostra + conf*m.estr$erro.padrao
m.estr <- merge(m.estr, pop[,c("p_date","mean")], by="p_date")
m.estr$col <- ifelse(m.estr$mean >= m.estr$ic.inf & m.estr$mean <= m.estr$ic.sup,"darkblue","red")
# Número de pontos no intervalo de confiança (darkblue)
table(m.estr$col)
# Salva o grafico de comparacao da serie temporal populacional e amostral.
pdf(paste0(img.dir, "_Time_series_pop_random_sample_392080.pdf"))
plot(m.estr[c("p_date","mean")],col=m.estr$col,type="o",lwd=1,axes = T,cex=0.7, xlab="Ano", ylim=c(90,190), ylab="Média de valores do Bolsa Familia")
lines(m.estr[c("p_date","mean.amostra")],col="green",lwd=2)
lines(m.estr[c("p_date","ic.inf")], col="red",lty=2)
lines(m.estr[c("p_date","ic.sup")], col="red",lty=2)
legend("topleft",legend = c("População","Amostra","Intervalo de confiaça"),col = c("Darkblue","green","red"),lty = c(1,1,2),bty = "n")
dev.off()


############# Variação do saldo de cadastrados ##########################################
# Calcula a média das medias geradas dos saldos cadastrados, o desvio padrao amostral e o intervalo de confianca.
s.estr$mean.amostra <- apply(s.estr[,3:(m+2)],1,mean)
s.estr$erro.padrao <- NA
for (i in 1:nrow(s.estr)){
  s.estr$erro.padrao[i] <-sqrt(sum((s.estr[i,3:(m+2)] - s.estr$mean.amostra[i])^2/(m-1)))
}
conf <- 1.96
s.estr$ic.inf <- s.estr$mean.amostra - conf*s.estr$erro.padrao
s.estr$ic.sup <- s.estr$mean.amostra + conf*s.estr$erro.padrao
s.estr <- merge(s.estr, pop[,c("p_date","pop.saldo")], by="p_date")
s.estr$col <- ifelse(s.estr$p.saldo >= s.estr$ic.inf & s.estr$p.saldo <= s.estr$ic.sup,"darkblue","red")

# Número de pontos no intervalo de confiança (darkblue)
table(s.estr$col)
# Salva o grafico de comparacao da serie temporal populacional e amostral.
pdf(paste0(img.dir, "Saldo de cadastrados_Time_series_pop_random_sample_392080.pdf"))
plot(s.estr[c("p_date","p.saldo")],col=s.estr$col,type="o",lwd=1,axes = T,cex=0.7, xlab="Ano", ylab="Variação dos cadastrados no Bolsa Familia")
lines(s.estr[c("p_date","mean.amostra")],col="green",lwd=2)
lines(s.estr[c("p_date","ic.inf")], col="red",lty=2)
lines(s.estr[c("p_date","ic.sup")], col="red",lty=2)
legend("topleft",legend = c("População","Amostra","Intervalo de confiaça"),col = c("Darkblue","green","red"),lty = c(1,1,2),bty = "n")
dev.off()

############# Valor médio por UF##########################################
# Calcula a media das medias geradas, o desvio padrao amostral e o intervalo de confianca.

pontos <- NULL
for (uf in unique(substring(m.estr.uf$chave,1,2))){
  bd <- m.estr.uf[substring(m.estr.uf$chave,1,2)==uf,]
  bd$p_date <- as.Date.character(substring(bd$chave,3,nchar(bd$chave)),"%Y-%m-%d")
  bd$mean.amostra <- apply(bd[,3:(m+2)],1,mean)
  bd$erro.padrao <- NA
  for (i in 1:nrow(bd)){
    bd$erro.padrao[i] <-sqrt(sum((bd[i,3:(m+2)] - bd$mean.amostra[i])^2/(m-1)))
  }
  conf <- 1.96
  bd$ic.inf <- bd$mean.amostra - conf*bd$erro.padrao
  bd$ic.sup <- bd$mean.amostra + conf*bd$erro.padrao
  bd <- merge(bd, pop.uf[pop.uf$state == uf,c("p_date","mean")], by="p_date")
  bd$col <- ifelse(bd$mean >= bd$ic.inf & bd$mean <= bd$ic.sup,"darkblue","red")
  # Número de pontos no intervalo de confiança (darkblue)

  pontos <- rbind(pontos, data.frame(uf = uf, data.frame(table(bd$col))))
  
  # Salva o grafico de comparacao da serie temporal populacional e amostral.
  pdf(paste0(img.dir,uf, "_Time_series_pop_random_sample_392080.pdf"))
  plot(bd[c("p_date","mean")],col=bd$col,type="o",lwd=1,axes = T,cex=0.7, xlab="Ano", ylim=c(min(c(bd$ic.inf,bd$ic.sup)),max(c(bd$ic.inf,bd$ic.sup))), ylab="Média de valores do Bolsa Familia")
  lines(bd[c("p_date","mean.amostra")],col="green",lwd=2)
  lines(bd[c("p_date","ic.inf")], col="red",lty=2)
  lines(bd[c("p_date","ic.sup")], col="red",lty=2)
  legend("topleft",legend = c("População","Amostra","Intervalo de confiaça"),col = c("Darkblue","green","red"),lty = c(1,1,2),bty = "n")
  dev.off()
}

write.csv(spread(pontos, Var1,Freq),paste0(data.dir,"Ajuste por UF.csv"))



# Tabela com os dados amostrais por UF
tab <- data.frame(random=data.frame(table(bd_random$state)),
           random.estrt=data.frame(table(bd_random.estr$state)))
write.csv(tab,"../data/Amostras por UF.csv")

#End