# Data

## Source

All data are retrieved directly from the **World Development Indicators (WDI)** database, maintained by the World Bank, using the [`WDI`](https://cran.r-project.org/package=WDI) R package.

No raw data file is stored in this repository. Running the analysis script fetches the data automatically via the API.

## How to Download

```r
library(WDI)

dados <- WDI(
  country = "all",
  indicator = c(
    gini     = "SI.POV.GINI",
    credito  = "FS.AST.PRVT.GD.ZS",
    pib_pc   = "NY.GDP.PCAP.KD.ZG",
    inflacao = "FP.CPI.TOTL.ZG",
    urbano   = "SP.URB.TOTL.IN.ZS"
  ),
  start = 2010,
  end   = 2022
)
```

## Sample Definition

- **Period:** 2010–2022
- **Universe:** All available countries
- **Exclusions:**
  - High-income countries (OECD and Gulf states)
  - Regional aggregates and non-country entries (identified by numeric or multi-character ISO codes)
- **Minimum observation requirement:** Countries with fewer than 5 non-missing Gini observations are excluded

## Variable Codes

| Variable | WDI Indicator | Description |
|---|---|---|
| `gini` | SI.POV.GINI | Gini index (income inequality) |
| `credito` | FS.AST.PRVT.GD.ZS | Domestic credit to private sector (% GDP) |
| `pib_pc` | NY.GDP.PCAP.KD.ZG | GDP per capita growth (annual %) |
| `inflacao` | FP.CPI.TOTL.ZG | Inflation, consumer prices (annual %) |
| `urbano` | SP.URB.TOTL.IN.ZS | Urban population (% of total) |
