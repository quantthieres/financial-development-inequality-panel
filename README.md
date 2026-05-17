# Financial Development and Inequality: Evidence from Panel Data

**Desenvolvimento Financeiro e Desigualdade: Evidências em Dados em Painel**

## Overview

This project investigates whether financial development — measured by private credit as a share of GDP — is associated with reduced income inequality, measured by the Gini index, in developing countries.

## Research Question

Does greater access to private credit reduce income inequality in developing countries?

## Hypothesis

Based on the finance-growth-inequality literature, financial deepening may reduce inequality by expanding access to capital for lower-income households and small firms. However, in the short run, credit may primarily benefit higher-income groups, potentially increasing inequality.

## Data

- **Source:** World Development Indicators (World Bank), accessed via the `WDI` R package
- **Period:** 2010–2022
- **Sample:** Developing countries (high-income countries and regional aggregates excluded)
- **No raw data file is stored in this repository** — the dataset is downloaded directly at runtime (see `data/README.md`)

## Variables

**Dependent variable:**
- `gini`: Gini index of income inequality (SI.POV.GINI)

**Main variable of interest:**
- `credito_lag`: Private credit to the private sector (% GDP), one-period lag (FS.AST.PRVT.GD.ZS)

**Controls:**
- `pib_pc`: GDP per capita growth (NY.GDP.PCAP.KD.ZG)
- `inflacao`: Inflation, consumer prices (FP.CPI.TOTL.ZG)
- `urbano`: Urban population (% of total) (SP.URB.TOTL.IN.ZS)

## Methods

The following panel data estimators are implemented:

| Model | Description |
|---|---|
| Pooled OLS | Baseline, ignores unobserved heterogeneity |
| Fixed Effects (one-way) | Controls for country-specific effects |
| Fixed Effects (two-way) | Controls for country and time effects |
| Random Effects (Swamy-Arora) | GLS with random country effects |
| GMM Difference (Arellano-Bond) | Addresses endogeneity and dynamic bias |
| GMM System (Blundell-Bond) | Adds level equations for efficiency |
| Local Projections (panel) | Traces the dynamic response path of Gini |

All static models use Arellano-robust standard errors clustered at the country level. GMM results use two-step robust standard errors.

## Main Results

Os resultados indicam evidência parcial de que maior crédito ao setor privado está associado à redução da desigualdade de renda em países em desenvolvimento. A relação aparece nos modelos de efeitos fixos, efeitos aleatórios, GMM Difference e Local Projections. No entanto, o GMM System sugere que o efeito do crédito perde significância quando se controla de forma mais intensa a persistência do Gini, indicando sensibilidade à especificação dinâmica.

## Limitations

- Gini data coverage is unbalanced across countries and years, reducing effective sample size
- The exclusion of high-income countries limits external validity
- Financial development is proxied by a single credit variable; broader measures (e.g., financial inclusion indices) are not used
- Instrument proliferation in GMM is partially mitigated by restricting lag depth to 2–3 periods

## Outputs

### Tables

| File | Description |
|---|---|
| [outputs/tables/static_models.html](outputs/tables/static_models.html) | Pooled OLS, FE (1-way), FE (2-way), RE — with robust standard errors |
| [outputs/tables/dynamic_gmm_models.html](outputs/tables/dynamic_gmm_models.html) | GMM Difference and GMM System — two-step robust SEs |
| [outputs/tables/gmm_simple_table.html](outputs/tables/gmm_simple_table.html) | Simplified GMM results (coefficients, SEs, p-values) |
| [outputs/tables/static_models.png](outputs/tables/static_models.png) | Static models table (image) |
| [outputs/tables/dynamic_gmm_models.png](outputs/tables/dynamic_gmm_models.png) | GMM models table (image) |

### Figures

| File | Description |
|---|---|
| [outputs/figures/raw_correlation_credit_gini.png](outputs/figures/raw_correlation_credit_gini.png) | Raw scatter plot: lagged credit vs. Gini |
| [outputs/figures/fixed_effects_credit_gini.png](outputs/figures/fixed_effects_credit_gini.png) | Within-country variation: demeaned credit vs. demeaned Gini |
| [outputs/figures/static_model_coefficients.png](outputs/figures/static_model_coefficients.png) | Comparison of `credito_lag` coefficients across static models |
| [outputs/figures/local_projections_irf.png](outputs/figures/local_projections_irf.png) | Cumulative IRF: Gini response to credit shock via Local Projections |

## How to Reproduce

1. Install R (>= 4.0) and the required packages (see below)
2. Open `scripts/panel_credit_gini_analysis.R`
3. Run the script from top to bottom — tables are exported to `outputs/tables/` and figures are rendered in the R graphics device

No data download is required in advance — the `WDI` package fetches the data automatically.

## Required R Packages

```r
install.packages(c(
  "WDI",           # World Development Indicators API
  "plm",           # Panel data models
  "dplyr",         # Data manipulation
  "lmtest",        # Hypothesis tests
  "sandwich",      # Robust standard errors
  "ggplot2",       # Graphics
  "lpirfs",        # Local Projections
  "modelsummary"   # Regression tables
))
```

## Repository Structure

```
.
├── README.md
├── .gitignore
├── scripts/
│   └── panel_credit_gini_analysis.R
├── outputs/
│   ├── tables/
│   │   ├── static_models.html
│   │   ├── dynamic_gmm_models.html
│   │   ├── gmm_simple_table.html
│   │   ├── static_models.png
│   │   └── dynamic_gmm_models.png
│   └── figures/
│       ├── raw_correlation_credit_gini.png
│       ├── fixed_effects_credit_gini.png
│       ├── static_model_coefficients.png
│       ├── local_projections_irf.png
│       └── README.md
├── slides/
│   └── financial_development_inequality_panel.pdf
└── data/
    └── README.md
```

## Citation

World Bank (2024). World Development Indicators. Retrieved via the `WDI` R package.
