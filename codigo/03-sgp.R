# Carregando dados apenas para CPFs presentes em lista_cpfs_folha
sgp <- data.table::fread(
    paste0(dados_dir, "SGP_AGO_25.csv"),
    showProgress = TRUE
) %>%
    mutate(cpf = str_pad(str_replace_all(as.character(nu_cpf), "\\D",""), 11, pad = "0")) %>%
    filter(cpf %in% lista_cpfs_folha)

# Criação de flag pra CPF no SGP
sgp_cpfs <- sgp %>% mutate(indicador_sgp = 1L)

# Junção do SGP com as folhas
folhas_com_indicador_sgp <- detalhes_todos %>%
  left_join(sgp_cpfs, by = "cpf") %>%
  mutate(indicador_sgp = coalesce(indicador_sgp, 0L))

# CPFs da folha dentro e fora do SGP
na_folha_e_no_sgp      <- folhas_com_indicador_sgp %>% filter(indicador_sgp == 1L)
na_folha_e_fora_do_sgp <- folhas_com_indicador_sgp %>% filter(indicador_sgp == 0L)

# Resumos do tabelão "folha+sgp"
resumo_sgp_geral <- folhas_com_indicador_sgp %>%
  summarise(linhas_total = n(), cpfs_unicos_total = n_distinct(cpf),
            linhas_no_sgp = sum(indicador_sgp==1L), linhas_fora_sgp = sum(indicador_sgp==0L),
            cpfs_no_sgp = n_distinct(cpf[indicador_sgp==1L]),
            cpfs_fora_sgp = n_distinct(cpf[indicador_sgp==0L]))

# Exportar tabela de CPFs das folhas que não estão no SGP para a pasta SAIDA e tabela com resumos também
data.table::fwrite(na_folha_e_fora_do_sgp %>% distinct(cpf),
                   file.path(pasta_saida, "cpfs_fora_sgp_unicos.csv"))
data.table::fwrite(resumo_sgp_geral, file.path(pasta_saida, "resumo_sgp_geral.csv"))
