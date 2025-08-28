start <- Sys.time()

# Criando Data Table da Folha
conexao_folha <- arrow::open_dataset(paste0(dir_dados, "/intermediary/folhas_detalhes_todos.parquet"))

dt_folha <- conexao_folha %>%
  #head(10) %>% # para testes
  data.table::as.data.table()

rm(conexao_folha)

# Criando Data Table SGP apenas com CPFs que estão na Folha
conexao_sgp <- open_dataset(
  sources = paste0(dir_dados, "/raw/sgp/SGP_AGO_FELIPE.csv"),
  format = "csv",
  delimiter = ";",
  col_names = TRUE,
  col_types = schema(nu_cpf = string())
)

dt_sgp <- conexao_sgp %>%
  mutate(cpf = as.character(nu_cpf)) %>% #transforma a coluna 'nu_cpf' em texto, remove caracteres não numéricos, e preenche à esquerda com zeros até completar 11 dígitos, criando a nova coluna 'cpf'
  filter(cpf %in% unique(dt_folha$cpf)) %>%
  data.table::as.data.table()

rm(conexao_sgp)

# Número de CPFs da folha atual que não estão no SGP

n_linhas_folha                  <- length(dt_folha$cpf)
n_linhas_folha_dent_sgp         <- length(dt_folha[cpf %in% unique(dt_sgp$cpf), ]$cpf)
n_linhas_folha_fora_sgp         <- length(dt_folha[!cpf %in% unique(dt_sgp$cpf), ]$cpf)

cpfs_fora_sgp                   <- unique(dt_folha[!cpf %in% unique(dt_sgp$cpf), ]$cpf)

n_cpfs_folha                    <- length(unique(dt_folha$cpf))
n_cpfs_folha_dent_sgp           <- length(unique(dt_folha[cpf %in% unique(dt_sgp$cpf), ]$cpf))
n_cpfs_folha_fora_sgp           <- length(unique(dt_folha[!cpf %in% unique(dt_sgp$cpf), ]$cpf))


# Relatório
print("Número de linhas da folha atual:") # Cada linha da folha equivale a uma ordem de pagamento
print(n_linhas_folha)
print("Número de linhas da folha atual que estão no SGP:")
print(n_linhas_folha_dent_sgp)
print("Número de linhas da folha atual que não estão no SGP:")
print(n_linhas_folha_fora_sgp)

print("Número de CPFs da folha atual:")
print(n_cpfs_folha)
print("Número de CPFs da folha atual que não estão no SGP:")
print(n_cpfs_folha_fora_sgp)
print("Número de CPFs da folha atual que estão no SGP:")
print(n_cpfs_folha_dent_sgp)



# Tempo de execução
end <- Sys.time()
print(end - start)

# Apagando itens desnecessários da memória
rm(dt_folha, dt_sgp, start, end)

# Fim do script