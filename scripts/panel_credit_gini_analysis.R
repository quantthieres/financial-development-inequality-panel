# ============================================================
# Desenvolvimento Financeiro e Desigualdade:
# Evidências em Dados em Painel
# ============================================================
# Descricao: Estima a relacao entre credito ao setor privado
#            e desigualdade de renda (Gini) em paises em
#            desenvolvimento, usando dados do WDI (2010-2022).
# ============================================================


# ── a) Pacotes ───────────────────────────────────────────────

# Instalacao opcional (descomente se necessario):
# install.packages(c("WDI", "plm", "dplyr", "lmtest", "sandwich",
#                    "ggplot2", "lpirfs", "modelsummary"))

library(WDI)
library(plm)
library(dplyr)
library(lmtest)
library(sandwich)
library(ggplot2)
library(lpirfs)
library(modelsummary)


# ── b) Coleta dos dados ──────────────────────────────────────

dados <- WDI(
  country = "all",
  indicator = c(
    gini     = "SI.POV.GINI",        # indice de Gini
    credito  = "FS.AST.PRVT.GD.ZS",  # credito ao setor privado (% PIB)
    pib_pc   = "NY.GDP.PCAP.KD.ZG",  # crescimento do PIB per capita
    inflacao = "FP.CPI.TOTL.ZG",     # inflacao
    urbano   = "SP.URB.TOTL.IN.ZS"   # populacao urbana (%)
  ),
  start = 2010,
  end   = 2022)


# ── c) Limpeza e construcao do painel ────────────────────────

excluir <- c(
  "AT","AU","BE","CA","CH","DE","DK","ES","FI","FR",
  "GB","GR","IE","IS","IT","JP","KR","LU","NL","NO",
  "NZ","PT","SE","US","IL","SG","HK","QA","AE","KW",
  "BH","OM","SA","BN","MC","SM","LI","AD")

dados_limpos <- dados %>%
  filter(!iso2c %in% excluir) %>%
  filter(!grepl("^[0-9]", iso2c)) %>%
  filter(nchar(iso2c) == 2) %>%
  mutate(
    year     = as.integer(year),
    inflacao = ifelse(inflacao > 100 | inflacao < -20, NA, inflacao),
    pib_pc   = ifelse(abs(pib_pc) > 25, NA, pib_pc),
    credito  = ifelse(credito > 200, NA, credito)
  ) %>%
  group_by(iso2c) %>%
  filter(sum(!is.na(gini)) >= 5) %>%
  ungroup() %>%
  arrange(iso2c, year)

painel <- pdata.frame(dados_limpos, index = c("iso2c", "year"))

painel$credito_lag <- plm::lag(painel$credito, 1)
painel$gini_lag    <- plm::lag(painel$gini, 1)

base_modelo <- painel %>%
  as.data.frame() %>%
  filter(
    !is.na(gini),
    !is.na(credito),
    !is.na(credito_lag),
    !is.na(pib_pc),
    !is.na(inflacao),
    !is.na(urbano)
  ) %>%
  arrange(iso2c, year)

painel_final <- pdata.frame(base_modelo, index = c("iso2c", "year"))


# ── d) Modelos estaticos ─────────────────────────────────────

# Modelo 1: Pooled OLS
modelo_pooled_lag <- plm(
  gini ~ credito_lag + pib_pc + inflacao + urbano,
  data  = painel_final,
  model = "pooling")

summary(modelo_pooled_lag)
coeftest(modelo_pooled_lag, vcov = vcovHC(modelo_pooled_lag, type = "HC1"))

# Modelo 2: Efeitos Fixos one-way
modelo_fe_1 <- plm(
  gini ~ credito_lag + pib_pc + inflacao + urbano,
  data   = painel_final,
  model  = "within",
  effect = "individual"
)

summary(modelo_fe_1)
coeftest(
  modelo_fe_1,
  vcov = vcovHC(modelo_fe_1, method = "arellano", type = "HC1", cluster = "group")
)

# Modelo 3: Efeitos Fixos two-way (principal)
modelo_fe_2 <- plm(
  gini ~ credito_lag + pib_pc + inflacao + urbano,
  data   = painel_final,
  model  = "within",
  effect = "twoways"
)

summary(modelo_fe_2)
coeftest(
  modelo_fe_2,
  vcov = vcovHC(modelo_fe_2, method = "arellano", type = "HC1", cluster = "group")
)

# Modelo 4: Efeitos Aleatorios
modelo_re <- plm(
  gini ~ credito_lag + pib_pc + inflacao + urbano,
  data          = painel_final,
  model         = "random",
  effect        = "individual",
  random.method = "swar"
)

summary(modelo_re)
coeftest(
  modelo_re,
  vcov = vcovHC(modelo_re, method = "arellano", type = "HC1", cluster = "group")
)


# ── e) Testes diagnosticos ───────────────────────────────────

pFtest(modelo_fe_1, modelo_pooled_lag)   # FE vs Pooled
phtest(modelo_fe_1, modelo_re)           # Hausman: FE vs RE
pbgtest(modelo_fe_2)                     # Autocorrelacao serial
bptest(modelo_pooled_lag)                # Heterocedasticidade


# ── f) Modelos GMM ───────────────────────────────────────────

# Modelo 5: GMM Difference (Arellano-Bond)
# Usa poucos instrumentos para reduzir risco de excesso de instrumentos
modelo_gmm <- pgmm(
  gini ~ lag(gini, 1) + credito_lag + pib_pc + inflacao + urbano |
    lag(gini, 2:3),
  data           = painel_final,
  effect         = "individual",
  model          = "twosteps",
  transformation = "d"
)

summary(modelo_gmm, robust = TRUE)

# Modelo 6: GMM System (Blundell-Bond)
modelo_gmm_sys <- pgmm(
  gini ~ lag(gini, 1) + credito_lag + pib_pc + inflacao + urbano |
    lag(gini, 2:3),
  data           = painel_final,
  effect         = "individual",
  model          = "twosteps",
  transformation = "ld"
)

summary(modelo_gmm_sys, robust = TRUE)


# ── g) Local Projections ─────────────────────────────────────

# O pacote lpirfs espera que as duas primeiras colunas sejam id e tempo
data_lp <- as.data.frame(painel_final) %>%
  mutate(
    id        = as.character(iso2c),
    year      = as.integer(year),
    gini      = as.numeric(gini),
    credito   = as.numeric(credito),
    pib_pc    = as.numeric(pib_pc),
    inflacao  = as.numeric(inflacao),
    urbano    = as.numeric(urbano),
    gini_lag  = as.numeric(gini_lag)
  ) %>%
  select(id, year, gini, credito, pib_pc, inflacao, urbano, gini_lag) %>%
  arrange(id, year) %>%
  filter(
    !is.na(gini),
    !is.na(credito),
    !is.na(pib_pc),
    !is.na(inflacao),
    !is.na(urbano),
    !is.na(gini_lag)
  )

controles_lp <- c("pib_pc", "inflacao", "urbano", "gini_lag")
H <- 6  # horizontes: h = 0, 1, 2, 3, 4, 5

modelo_lp <- lp_lin_panel(
  data_set      = data_lp,
  endog_data    = "gini",
  cumul_mult    = TRUE,
  shock         = "credito",
  diff_shock    = FALSE,
  panel_model   = "within",
  panel_effect  = "twoways",
  robust_cov    = "vcovSCC",
  robust_type   = "HC3",
  robust_maxlag = NULL,
  c_exog_data   = controles_lp,
  confint       = 1.645,
  hor           = H
)

plot(modelo_lp)

irf_lp <- data.frame(
  horizonte = 0:(H - 1),
  resposta  = as.numeric(modelo_lp$irf_panel_mean[1, ]),
  inferior  = as.numeric(modelo_lp$irf_panel_low[1, ]),
  superior  = as.numeric(modelo_lp$irf_panel_up[1, ])
)

print(irf_lp)


# ── h) Graficos ──────────────────────────────────────────────

df <- as.data.frame(painel_final)
df$credito_lag <- as.numeric(df$credito_lag)
df$gini        <- as.numeric(df$gini)

df <- df %>%
  group_by(iso2c) %>%
  mutate(
    credito_lag_fe = credito_lag - mean(credito_lag, na.rm = TRUE),
    gini_fe        = gini - mean(gini, na.rm = TRUE)
  ) %>%
  ungroup()

# Correlacao bruta: credito defasado vs Gini
ggplot(df, aes(x = credito_lag, y = gini)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Credito Defasado vs Desigualdade (correlacao bruta)",
    x = "Credito ao setor privado defasado (% PIB)",
    y = "Gini"
  ) +
  theme_minimal()

# Variacao within-country (efeitos fixos)
ggplot(df, aes(x = credito_lag_fe, y = gini_fe)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Credito Defasado vs Desigualdade (Efeitos Fixos)",
    x = "Credito defasado (variacao dentro do pais)",
    y = "Gini (variacao dentro do pais)"
  ) +
  theme_minimal()

# Comparacao de coeficientes entre modelos estaticos
coeficientes <- c(
  coef(modelo_pooled_lag)["credito_lag"],
  coef(modelo_fe_1)["credito_lag"],
  coef(modelo_fe_2)["credito_lag"],
  coef(modelo_re)["credito_lag"]
)

nomes <- c("Pooled", "FE 1-way", "FE 2-way", "RE")

plot(coeficientes, type = "b", pch = 19,
     xaxt = "n",
     xlab = "Modelo",
     ylab = "Coeficiente do Credito",
     main = "Comparacao entre Modelos Estaticos")

axis(1, at = 1:4, labels = nomes)
abline(h = 0, lty = 2)

# Local Projection: resposta acumulada do Gini ao credito
ggplot(irf_lp, aes(x = horizonte, y = resposta)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_ribbon(aes(ymin = inferior, ymax = superior), alpha = 0.2) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 0:(H - 1)) +
  labs(
    title = "Local Projection: resposta do Gini ao aumento do credito",
    subtitle = "Resposta acumulada | IC 90% | Erros Driscoll-Kraay",
    x = "Anos apos o aumento do credito",
    y = "Resposta acumulada do Gini"
  ) +
  theme_minimal()


# ── i) Tabelas ───────────────────────────────────────────────

# Tabela de modelos estaticos
modelsummary(
  list(
    "Pooled OLS" = modelo_pooled_lag,
    "FE (1-way)" = modelo_fe_1,
    "FE (2-way)" = modelo_fe_2,
    "RE"         = modelo_re
  ),
  vcov = list(
    vcovHC(modelo_pooled_lag, type = "HC1"),
    vcovHC(modelo_fe_1, method = "arellano", type = "HC1", cluster = "group"),
    vcovHC(modelo_fe_2, method = "arellano", type = "HC1", cluster = "group"),
    vcovHC(modelo_re,   method = "arellano", type = "HC1", cluster = "group")
  ),
  stars      = TRUE,
  statistic  = "std.error",
  gof_omit   = "AIC|BIC|Log.Lik|RMSE",
  title      = "Modelos Estaticos: Pooled OLS, Efeitos Fixos e Efeitos Aleatorios",
  notes      = "+ p<0.1, * p<0.05, ** p<0.01, *** p<0.001. Erros padrao robustos entre parenteses.",
  output     = "outputs/tables/static_models.html"
)

# Tabela de modelos GMM (formato classico: coef + SE robusto entre parenteses)
sum_gmm_diff <- summary(modelo_gmm, robust = TRUE)
sum_gmm_sys  <- summary(modelo_gmm_sys, robust = TRUE)

gmm_diff_rob <- sum_gmm_diff$coefficients
gmm_sys_rob  <- sum_gmm_sys$coefficients

vars <- c("lag(gini, 1)", "credito_lag", "pib_pc", "inflacao", "urbano")

var_labels <- c("Gini defasado", "Credito defasado", "PIB per capita",
                "Inflacao", "Urbanizacao")

add_stars <- function(coef, pval) {
  stars <- ifelse(pval < 0.001, "***",
           ifelse(pval < 0.01,  "**",
           ifelse(pval < 0.05,  "*",
           ifelse(pval < 0.1,   "+", ""))))
  paste0(formatC(coef, format = "f", digits = 3), stars)
}

rows <- vector("list", length(vars) * 2)
for (i in seq_along(vars)) {
  v <- vars[i]

  coef_diff <- round(gmm_diff_rob[v, "Estimate"],    3)
  se_diff   <- round(gmm_diff_rob[v, "Std. Error"],  3)
  p_diff    <-       gmm_diff_rob[v, "Pr(>|z|)"]

  coef_sys  <- round(gmm_sys_rob[v,  "Estimate"],    3)
  se_sys    <- round(gmm_sys_rob[v,  "Std. Error"],  3)
  p_sys     <-       gmm_sys_rob[v,  "Pr(>|z|)"]

  rows[[2 * i - 1]] <- data.frame(
    Variavel       = var_labels[i],
    GMM_Difference = add_stars(coef_diff, p_diff),
    GMM_System     = add_stars(coef_sys,  p_sys),
    stringsAsFactors = FALSE
  )
  rows[[2 * i]] <- data.frame(
    Variavel       = "",
    GMM_Difference = paste0("(", formatC(se_diff, format = "f", digits = 3), ")"),
    GMM_System     = paste0("(", formatC(se_sys,  format = "f", digits = 3), ")"),
    stringsAsFactors = FALSE
  )
}

tabela_gmm_html <- do.call(rbind, rows)

print(tabela_gmm_html)

datasummary_df(
  tabela_gmm_html,
  title  = "Modelos GMM: GMM Difference (Arellano-Bond) e GMM System (Blundell-Bond)",
  notes  = "+ p<0.1, * p<0.05, ** p<0.01, *** p<0.001. Erros padrao robustos (dois passos) entre parenteses.",
  output = "outputs/tables/dynamic_gmm_models.html"
)
