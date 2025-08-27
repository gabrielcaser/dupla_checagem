############################################################
# GCS → R com progresso por ARQUIVO (curl) usando Service Account
# Bucket: pe-de-meia
# Pastas preset: sgp/, cad_unico/, folhas de pagamento/
#
# ATENÇÃO: Altere caminhos marcados como "ALTERAR SE NECESSÁRIO"
############################################################

# 0) Pacotes --------------------------------------------------------------
pkgs <- c("gargle", "curl", "jsonlite", "progress")
instalar <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(instalar)) install.packages(instalar, repos = "https://cloud.r-project.org")
library(gargle)
library(curl)
library(jsonlite)
library(progress)

# 1) Configurações --------------------------------------------------------
bucket <- "pe-de-meia"

# >>>>>> ALTERAR SE NECESSÁRIO (CAMINHO DO .JSON DA SERVICE ACCOUNT) <<<<<<
sa_json <- "C:\\SUA_PASTA_COM_A_CHAVE\\rwilliammelo-5d1e9f4671a5.json"

# >>>>>> ALTERAR SE NECESSÁRIO (PASTA LOCAL DE DOWNLOAD) <<<<<<
destino_base <- "C:\\SUA_PASTA_DE_DOWNLOADS"
dest_sgp     <- file.path(destino_base, "sgp")
dest_cad     <- file.path(destino_base, "cad_unico")
dest_folhas  <- file.path(destino_base, "folhas de pagamento")

scope_read <- "https://www.googleapis.com/auth/devstorage.read_only"

# 2) Autenticação (gera access_token) ------------------------------------
tok <- gargle::credentials_service_account(path = sa_json, scopes = scope_read)
access_token <- tok$credentials$access_token

# 3) Helpers --------------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a)) b else a

garantir_dir <- function(p) {
  if (file.exists(p) && !dir.exists(p)) unlink(p, force = TRUE)
  if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

enc_bucket <- utils::URLencode(bucket, reserved = TRUE)
enc_obj    <- function(x) gsub("/", "%2F", utils::URLencode(x, reserved = TRUE), fixed = TRUE)

# 3.1) Listar objetos via API (com paginação; sem httr)
listar_gcs <- function(bucket, prefixo = "", access_token) {
  base <- sprintf("https://storage.googleapis.com/storage/v1/b/%s/o", enc_bucket)
  h <- curl::new_handle()
  curl::handle_setheaders(h, Authorization = paste("Bearer", access_token))
  page_token <- NULL
  acc <- character()
  
  repeat {
    q <- list(prefix = prefixo, maxResults = 1000L)
    if (!is.null(page_token)) q$pageToken <- page_token
    qs <- paste0(names(q), "=", vapply(q, curl::curl_escape, character(1)), collapse = "&")
    url <- paste0(base, "?", qs)
    
    res <- curl::curl_fetch_memory(url, handle = h)
    if (res$status_code >= 400) {
      stop("Erro na listagem (HTTP ", res$status_code, "): ", rawToChar(res$content))
    }
    ct <- jsonlite::fromJSON(rawToChar(res$content))
    if (!is.null(ct$items)) acc <- c(acc, ct$items$name)
    page_token <- ct$nextPageToken
    if (is.null(page_token) || page_token == "") break
  }
  
  unique(na.omit(acc))
}

# 3.2) Remover marcadores de pasta
remover_marcadores <- function(objs) {
  is_marker <- function(o, todos) {
    if (is.na(o) || o == "") return(TRUE)
    if (grepl("/$", o)) return(TRUE)
    if (!grepl("/", o) && any(startsWith(todos, paste0(o, "/")))) return(TRUE)
    FALSE
  }
  objs[!vapply(objs, is_marker, logical(1), todos = objs)]
}

# 3.3) Baixar um arquivo com progresso (curl)
baixar_um <- function(object_name, destino_completo, access_token) {
  garantir_dir(dirname(destino_completo))
  url <- sprintf(
    "https://storage.googleapis.com/download/storage/v1/b/%s/o/%s?alt=media",
    enc_bucket, enc_obj(object_name)
  )
  h <- curl::new_handle()
  curl::handle_setheaders(h, Authorization = paste("Bearer", access_token))
  # quiet = FALSE -> imprime barra de progresso nativa (bytes/tempo)
  curl::curl_download(url, destino_completo, handle = h, mode = "wb", quiet = FALSE)
  invisible(TRUE)
}

# 3.4) Baixar vários (barra geral entre arquivos)
baixar_varios <- function(objs, destino, sobrescrever = TRUE, access_token) {
  garantir_dir(destino)
  pb <- progress::progress_bar$new(
    format = "  Arquivos [:bar] :percent | :current/:total | :elapsed | ETA: :eta",
    total  = length(objs), clear = FALSE, width = 80
  )
  res_list <- vector("list", length(objs))
  for (i in seq_along(objs)) {
    obj <- objs[i]
    arq_local <- file.path(destino, obj)
    garantir_dir(dirname(arq_local))
    
    status <- "ok"; erro <- NA_character_
    if (file.exists(arq_local) && !sobrescrever) {
      status <- "pulado"
    } else {
      cat("\n⬇️  Downloading ", obj, "\n", sep = "")
      tryCatch(
        baixar_um(obj, arq_local, access_token = access_token),
        error = function(e) { status <<- "falha"; erro <<- conditionMessage(e) }
      )
    }
    
    res_list[[i]] <- data.frame(
      objeto  = obj,
      destino = arq_local,
      status  = status,
      erro    = erro,
      stringsAsFactors = FALSE
    )
    pb$tick()
  }
  do.call(rbind, res_list)
}

baixar_prefixo <- function(prefixo, destino, sobrescrever = TRUE, access_token) {
  cat("\n>>> Prefixo:", prefixo, "\nDestino:", destino, "\n")
  objs <- listar_gcs(bucket, prefixo, access_token)
  objs <- unique(remover_marcadores(objs))
  if (length(objs) == 0) { cat("Nenhum objeto encontrado.\n"); return(invisible(NULL)) }
  res <- baixar_varios(objs, destino, sobrescrever, access_token)
  ok <- sum(res$status == "ok"); falhas <- sum(res$status == "falha")
  cat("\nResumo — OK:", ok, " | Falhas:", falhas, "\n")
  if (falhas > 0) print(subset(res, status == "falha", select = c("objeto","erro")), row.names = FALSE)
  invisible(res)
}

# 4) Executar presets -----------------------------------------------------
# Descomente os que desejar rodar:

# 4.1) sgp/
res_sgp <- baixar_prefixo("sgp/", destino = dest_sgp, sobrescrever = TRUE, access_token = access_token)

# 4.2) cad_unico/
# res_cad <- baixar_prefixo("cad_unico/", destino = dest_cad, sobrescrever = TRUE, access_token = access_token)

# 4.3) folhas de pagamento/
# res_folhas <- baixar_prefixo("folhas de pagamento/", destino = dest_folhas, sobrescrever = TRUE, access_token = access_token)

cat("\nTodos os downloads finalizados.\n")
