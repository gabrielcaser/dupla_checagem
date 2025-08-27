# Descrição - Esse programa é o script principal que roda os demais da dupla-checagem de elegibilidade do Pé de Meia

# Limpando memória e ambiente
rm(list = ls())
gc()

# Definindo o ambiente renv (define e instala localmente os pacotes nas versões que foram utilizadas)
##install.packages("renv")
renv::activate()

# Rodando os scripts
source("codigo/01-baixar.R") # Baixa Folhas de Pagamento, SGP e 
source("codigo/02-dupla-checagem-2.R")