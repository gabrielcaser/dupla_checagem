suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr) })

# Arquivo da tabela pessoa do CadUnico - caminho identificado pelo padrão dos nomes dos arquivos tal como vem do MDS. Se necessário, ajustar ou passar caminho direto na função read_delim() ou equivalente. 

arquivo_cad_pessoa <- list.files(pasta_base, pattern="^ARQ_PESSOA_.*\\.csv$", full.names = TRUE)[1]

# Carregamento do CadUnico
cad_pessoa <- readr::read_delim(
  arquivo_cad_pessoa, delim = ";",
  locale = locale(encoding = "UTF-8"),
  col_types = cols(
    NU_CPF_PESSOA   = col_character(),
    NO_PESSOA       = col_character(),
    DT_NASC_PESSOA  = col_character(),
    CO_FAMILIAR_FAM = col_character()
  )
) %>%
  transmute(
    cpf            = str_pad(str_replace_all(NU_CPF_PESSOA, "[^0-9]", ""), 11, pad = "0"),
    nome_cad       = NO_PESSOA,
    data_nasc_cad  = DT_NASC_PESSOA,
    ID_FAMILIA     = CO_FAMILIAR_FAM
  ) %>%
  distinct(cpf, .keep_all = TRUE)

# Flag dos CPFs no CadUnico

cad_cpfs <- cad_pessoa %>% mutate(indicador_cad = 1L) %>% select(cpf, indicador_cad)

# Junção dos CPFs do CadUnico com as folhas de pagamento

folhas_com_cad <- detalhes_todos %>%
  distinct(cpf) %>%
  left_join(cad_cpfs, by="cpf") %>%
  mutate(indicador_cad = coalesce(indicador_cad, 0L))

# CPFs que estão nas folhas e não estão no CadUnico
cpfs_fora_cad <- folhas_com_cad %>% filter(indicador_cad == 0L) %>% select(cpf)

# Exportar esses CPFs fora do Cad para a pasta SAIDA
data.table::fwrite(cpfs_fora_cad, file.path(pasta_saida, "cpfs_fora_cad_unicos.csv"))
