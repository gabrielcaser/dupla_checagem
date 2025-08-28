# Descrição - Esse programa é o script principal que roda os demais da dupla-checagem de elegibilidade do Pé de Meia
## Versão do R utilizada: 4.5.1

# Limpando memória e ambiente
rm(list = ls())
gc()


# Diretórios
dir_base  <- "C:/Users/gabri/Documents/Github/MEC/dupla_checagem"
dir_dados <- "C:/Users/gabri/OneDrive - MEC-Ministério da Educação/dupla_checagem/dados"

# Definindo o ambiente renv (define e instala localmente os pacotes nas versões que foram utilizadas)
##install.packages("renv")
#renv::activate()

# Carregando pacotes
library(gargle)
library(curl)
library(jsonlite)
library(progress)
library(readr)
library(dplyr)
library(stringr)
library(tibble)
library(lubridate)
library(skimr)
library(arrow)

# Dados para baixar (1 = Sim, 0 = Não)
sgp              <- 0
cad_unico        <- 0
folhas_pagamento <- 1

# Rodando os scripts
#source("codigo/01-baixar.R") # Baixa Folhas de pagamento, SGP e Cad Único
#source(paste0(dir_base,"/codigo/02-folhas.R"))   # Processa Folhas de pagamento e seleciona CPFs do mês
source(paste0(dir_base,"/codigo/03-sgp.R"))      # Processa SGP e faz cruzamento com CPFs das folhas
#source("codigo/04-cadunico.R") # Processa CadÚnico e faz cruzamento com CPFs das folhas