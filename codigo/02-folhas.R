suppressPackageStartupMessages({
  library(readr); library(dplyr); library(stringr); library(tibble); library(lubridate)
})

pasta_base  <- "~/dupla_checagem"
pasta_2024  <- file.path(pasta_base, "ciclo2024_202508")
pasta_2025  <- file.path(pasta_base, "ciclo2025_202508")
pasta_saida <- file.path(pasta_base, "SAIDA"); dir.create(pasta_saida, FALSE, TRUE)

# Exemplos com folhas de agosto/2-25. Substituir pelos nomes corretos.

arquivos_2024 <- c(
  "simulado_CNT.PBS.PDPGT01.P1503.D250815.H135034.S00046.txt",
  "simulado_CNT.PBS.PDPGT01.P1503.D250815.H135055.S00046.txt",
  "simulado_CNT.PBS.PDPGT01.P1503.D250815.H135110.S00046.txt",
  "simulado_PBS.RJ.BOD1.M01.P1503.D250815.H135134.S00007.txt",
  "simulado_PBS.RJ.BOD1.M01.P1503.D250815.H135204.S00007.txt"
)
arquivos_2025 <- c(
  "simulado_CNT.PBS.PDPGT01.P1503.D250815.H135454.S00046.txt",
  "simulado_CNT.PBS.PDPGT01.P1503.D250815.H210022.S00046.txt"
)

# Catalogação das folhas para facilitar classificação de seus tipos

catalogo_folhas <- tibble(
  arquivo    = c(arquivos_2024, arquivos_2025),
  ciclo      = c(rep(2024, length(arquivos_2024)), rep(2025, length(arquivos_2025))),
  tipo_folha = c("aprovacao_deposito","conclusao","enem",
                 "liberacao_parcelas","devolucao_parcelas",
                 "matricula_frequencia","deposito")
) |>
  mutate(caminho = if_else(ciclo == 2024, file.path(pasta_2024, arquivo),
                                      file.path(pasta_2025, arquivo)))

# Função de leitura e processamento das folhas

ler_folha_detalhes <- function(caminho, arquivo, ciclo, tipo_folha){
  if (!file.exists(caminho)) return(tibble())
  tab <- read_fwf(
    caminho,
    fwf_positions(
      start = c(1,  3,  28, 46, 58, 64, 72, 80),
      end   = c(2, 13, 45, 57, 63, 71, 79, 81),
      col_names = c("registro","cpf_bruto","codigo_parcela","valor_centavos_txt",
                    "competencia_txt","data_inicio","data_fim","numero_parcela")
    ),
    col_types = cols(.default = col_character())
  )
  tab |>
    filter(substr(registro,1,2) %in% c("21","41")) |> # filtro nos registros de CPF
    transmute(
  arquivo, caminho, ciclo, tipo_folha,
  cpf            = str_replace_all(cpf_bruto, "\\D", ""),
  co_parcela     = codigo_parcela,     # padroniza
  valor_centavos = suppressWarnings(as.integer(valor_centavos_txt)),
  valor_reais    = valor_centavos/100,
  competencia    = suppressWarnings(as.integer(competencia_txt)),
  data_inicio, data_fim,
  nu_parcela     = numero_parcela      # padroniza
)

}

# Pega cada folha e aplica a função de processamento

detalhes_todos <- purrr::pmap_dfr(
  .l = list(
    caminho    = catalogo_folhas$caminho,
    arquivo    = catalogo_folhas$arquivo,
    ciclo      = catalogo_folhas$ciclo,
    tipo_folha = catalogo_folhas$tipo_folha
  ),
  .f = ler_folha_detalhes
) %>%
  mutate(cpf = stringr::str_pad(cpf, 11, pad = "0")) %>%
  filter(nchar(cpf) == 11)


# Exporta todos os arquivos de folha compilados em um dataframe, com tipo de folha
data.table::fwrite(detalhes_todos, file.path(pasta_saida, "detalhes_todos.csv.gz"))
arrow::write_parquet(detalhes_todos, file.path(pasta_saida, "detalhes_todos.parquet"), compression = "zstd")
