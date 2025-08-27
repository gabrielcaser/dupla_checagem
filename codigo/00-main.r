# Descrição - Esse programa é o script principal que roda os demais da dupla-checagem de elegibilidade do Pé de Meia
## Versão do R utilizada: 4.5.1

# Limpando memória e ambiente
rm(list = ls())
gc()

# Diretórios
dir_base  <- "C:/Users/gabri/Documents/Github/MEC/dupla_checagem"
dir_dados <- "C:/Users/gabri/OneDrive - MEC-Ministério da Educação/dupla_checagem"

# Definindo o ambiente renv (define e instala localmente os pacotes nas versões que foram utilizadas)
##install.packages("renv")
renv::activate()

# Carregando pacotes
library(gargle)
library(curl)
library(jsonlite)
library(progress)

# Dados para baixar (1 = Sim, 0 = Não)
sgp              <- 0
cad_unico        <- 0
folhas_pagamento <- 1

# Rodando os scripts
source("codigo/01-baixar.R") # Baixa Folhas de Pagamento, SGP e Cad Único
#source("codigo/02-dupla-checagem-2.R")