##########################################################################################
##                                      Pacotes                                         ##
##########################################################################################
library(tidyverse)
library(caret)
library(e1071)
library(rpart)
library(rpart.plot)
library(rattle)
library(randomForest)
library(caTools)
library(descr)
library(data.table)
library(readr)
library(kableExtra)
##########################################################################################
##                              Leitura de dados                                        ##
##########################################################################################


dados <- read_delim("Google Drive/Proyectos/Proceso-Semantix/bank-full.csv",";", escape_double = FALSE, trim_ws = TRUE)


##########################################################################################
##                                   Questão 1                                          ##
##########################################################################################

# Tabela 1

table(dados$job) %>% 
  kable(col.names = c("Variável","Frequência")) %>%
  kable_styling(bootstrap_options = "striped", full_width = F) %>% 
  scroll_box(height = "250px",box_css = "border: 1px solid #FFFFFF; padding: 5px; ")


## Grafico total Empréstimo

q1<-dados %>%
  filter(housing=="yes" | loan =="yes") %>%
  group_by(job) %>% 
  summarise(n=n())

ggplot(q1,aes(x=reorder(job, n),y=n))+
  geom_bar(stat = "identity")+
  ylab("Frequência")+
  xlab("Profissão")+
  coord_flip()+
  theme_bw()

## Grafico tipo de Empréstimo
q1_1<-dados %>%
  filter(housing=="yes") %>%
  group_by(job) %>% 
  summarise(n=n()) %>% 
  cbind(tipo="Housing")

q1_2<-dados %>%
  filter(loan=="yes") %>%
  group_by(job) %>% 
  summarise(n=n()) %>% 
  cbind(tipo="Loan")
  
df1<-rbind(q1_1, q1_2)
theme_set(theme_bw())
ggplot(arrange(df1, tipo),aes(x=reorder(job, n),y=n, fill=tipo))+
  geom_bar(stat = "identity", position=position_dodge())+
  ylab("Frequência")+
  xlab("Profissão")+
  coord_flip()+
  scale_fill_brewer(palette="Reds")+
  theme(legend.position = c(0.8, 0.25))
  
##########################################################################################
##                                   Questão 2                                          ##
##########################################################################################

# Grafico de Adesão

ggplot(data=dados, aes(x=campaign, fill=y))+
  geom_histogram()+
  ggtitle("Adesão baseada no número de contatos durante a campanha")+
  xlab("Número de contatos")+
  ylab("Frequência")+
  xlim(c(min=1,max=30)) +
  guides(fill=guide_legend(title="Adesão"))+
  scale_fill_brewer(palette="Reds")

## Quantis
Quantil_previous<-(dados %>% 
  filter(y=="yes"))$previous %>% 
  quantile(seq(0.1,1,0.1))
Quantil_campaign<-(dados %>% 
                     filter(y=="yes"))$campaign %>% 
  quantile(seq(0.1,1,0.1))

rbind(Campaign=Quantil_campaign,Previous=Quantil_previous) %>% 
  kable() %>%
  kable_styling("striped") %>%
  add_header_above(c(" " = 1, "Percentiles" = 10))

## Table de contingencia ##
df2<-dados %>% filter(y=="yes" & previous<8 & campaign<8) %>% select(campaign,previous)
ftable(df2[c("previous", "campaign")]) %>%
  prop.table() %>%
  as.data.frame() %>% 
  magrittr::set_colnames(c("Previous","Campaign","Proportion")) %>% 
  ggplot( aes(y = Previous, x = Campaign , fill= Proportion)) + 
  geom_tile()+
  scale_fill_gradient(low = "#FEE0D2", high = "#EF3B2C")

## Modelo de regressão
fit<- glm(ifelse(y=="yes",1,0) ~ campaign + previous + contact + pdays + duration, data=dados, family=binomial(link="logit"))
m1<-step(fit,trace=FALSE)
m1_result<-summary(m1)

m1_result$coefficients %>% 
  kable() %>%
  kable_styling("striped") %>%
  add_header_above(c(" " = 1, "Logistic model output" = 4))


df2<-dados %>% filter(campaign<32)
ftab <- CrossTable(df2$campaign,df2$y, prop.r = T,
                   prop.c = F,
                   prop.t = F,
                   prop.chisq = F)

ftab$prop.row %>% as.data.frame() %>% 
  ggplot(aes(x=reorder(x, Freq),y=Freq, fill=y))+
  geom_bar(stat = "identity")+
  ylab("y")+ 
  xlab("Ligações")+
  scale_fill_brewer(palette="Reds")

# Curva ROC

fit<- glm(ifelse(y=="yes",1,0) ~ campaign + previous + contact + pdays + duration, data=dados, family=binomial(link="logit"))
m1<-step(fit,trace=FALSE)
pred_lm = predict(m1, type='response')
## Fazer a curva ROC
rocr.pred = prediction(predictions = pred_lm, labels = dados$y)
precrec_obj <- evalmod(scores = rocr.pred@predictions, labels = rocr.pred@labels)
autoplot(precrec_obj)

##########################################################################################
##                                   Questão 3                                          ##
##########################################################################################
#Tabla Resumo
#Tabla Resumo
(dados %>% filter(y=="yes"))$campaign %>% 
  summary() %>%
  as.matrix() %>% t() %>% 
  kable() %>% 
  kable_styling("striped", full_width = F)

# Boxplot
dados %>% 
  filter(y=="yes") %>% 
  select(campaign) %>%
  ggplot(aes(x="Campaign",y=campaign,fill="#FEE0D2")) +
  ylab("Número de Contatos")+
  geom_boxplot()+
  stat_summary(fun.y=mean, geom="point", shape=20, size=5, color="red", fill="red")+
  theme(legend.position="none") +
  coord_flip()

##########################################################################################
##                                   Questão 4                                          ##
##########################################################################################
t1<-table(dados[c("poutcome","y")]) 
  t1 %>%
  as.matrix() %>% 
  kable() %>%
  kable_styling("striped") %>% 
  add_header_above(c("poutcome" = 1, "y" = 2))

  test<-chisq.test(t1)
  #show values of chisq.test()
  name(test)
  #Use xtable, use print.xtable for further manipulations
  out<-xtable::xtable(t1, caption=paste('Important table, chi-squared =', test$statistic, ', p=', test$p.value,',' ,test$parameter, 'df', sep=' ')) 
    
  #print
  out %>% 
  xtable2kable() %>% 
  kable_styling("striped",full_width = F) 

##########################################################################################
##                                   Questão 5                                          ##
##########################################################################################
# Tabela
  CrossTable(dados$default,dados$y, prop.r = T,
             prop.c = F,
             prop.t = F,
             prop.chisq = F)
# Modelo
  fit2<- glm(ifelse(default=="yes",1,0) ~ age+job+marital+education+balance+housing+loan+y, 
             data=dados, family=binomial(link="logit"))
  m2<-step(fit2,trace=FALSE)
  m2_result<-summary(m2)
  
##########################################################################################
##                                   Questão 6                                          ##
##########################################################################################
df4<-dados %>%
filter(housing=="yes")

#Grafico 3
df4%>%
select(age) %>%
ggplot(aes(x="Idade",y=age,fill="#FEE0D2")) +
geom_boxplot()+
stat_summary(fun.y=mean, geom="point", shape=20, size=5, color="red", fill="red")+
theme(legend.position="none") +
coord_flip()

#Grafico 4
df4 %>%
group_by(job) %>%
summarise(n=n()) %>%
ggplot(aes(x=reorder(job, n),y=n))+
geom_bar(stat = "identity",fill="#FC9272")+
ylab("Frequência")+
xlab("Profissão")+
coord_flip()+
scale_fill_brewer(palette="Reds")

#Grafico 5
df4 %>%
group_by(education) %>%
summarise(n=n()) %>%
ggplot(aes(x=reorder(education, n),y=n))+
geom_bar(stat = "identity",fill="#FC9272")+
ylab("Frequência")+
xlab("Education")+
coord_flip()+
scale_fill_brewer(palette="Reds")

#Grafico 6
df4%>%
select(balance) %>%
ggplot(aes(x = balance)) +
geom_histogram(fill="#FC9272")+
ylab("Frequência")+
xlab("Balance")

# Modelo de Regressão
fit3<- glm(ifelse(housing=="yes",1,0) ~ age+job+marital+education+balance+default+loan,
              data=dados, family=binomial(link="logit"))
m3<-step(fit3,trace=FALSE)
m3_result<-summary(m3)

  
##########################################################################################
##                      Dividir dados para treino e test                                ##
##########################################################################################  

sample <- sample.int(n = nrow(dados), size = floor(.75*nrow(dados)), replace = F)
traindata <- dados[sample, ]
testdata  <- dados[-sample, ]


###########################################
##             Modelos KNN               ##
###########################################

bank.knn <- train(y ~ ., data = traindata, method = "knn", 
                  maximize = TRUE,
                  trControl = trainControl(method = "cv", number = 10),
                  preProcess=c("center", "scale"))

predictedkNN <- predict(bank.knn , newdata = testdata)
confusionMatrix(predictedkNN , testdata$y)

###   Validação do Modelo
CrossTable(testdata$y, predictedkNN,
           prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
           dnn = c('actual default', 'predicted default'))