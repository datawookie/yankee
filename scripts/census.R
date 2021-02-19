# Data are from https://www.census.gov/data/tables/time-series/demo/popest/2010s-counties-total.html#par_textimage.

library(readr)
library(dplyr)
library(tidyr)
library(janitor)

URL <- "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv"
RAWNAME <- "co-est2019-alldata.csv"

if (file.exists(RAWNAME)) {
  message("Already have data.")
} else {
  message("Retrieving data.")
  download.file(URL, RAWNAME)
}

raw <- read_csv(RAWNAME) %>%
  clean_names()

census <- raw %>%
  pivot_longer(-(sumlev:ctyname)) %>%
  rename(
    level = sumlev,
    state_fips = state,
    county_fips = county,
    state_name = stname,
    county_name = ctyname
  ) %>%
  mutate(
    state_fips = as.integer(state_fips),
    county_fips = as.integer(county_fips),
    fips = as.integer(state_fips * 1000 + county_fips),
    level = case_when(
      level == "040" ~ "state",
      level == "050" ~ "county"
    ),
    region = case_when(
      region == "1" ~ "Northeast",
      region == "2" ~ "Midwest",
      region == "3" ~ "South",
      region == "4" ~ "West"
    ),
    division = case_when(
      division == "1" ~ "New England",
      division == "2" ~ "Middle Atlantic",
      division == "3" ~ "East North Central",
      division == "4" ~ "West North Central",
      division == "5" ~ "South Atlantic",
      division == "6" ~ "East South Central",
      division == "7" ~ "West South Central",
      division == "8" ~ "Mountain",
      division == "9" ~ "Pacific"
    ),
    level = factor(level),
    region = factor(region),
    division = factor(division)
  )

census <- census %>%
  extract(
    name,
    into = c("type", "year"),
    regex = "([^[:digit:]]*)([[:digit:]]*)"
  ) %>%
  filter(
      !(grepl("^gqestimates", type) | grepl("^(rbirth|rdeath|rnaturalinc|rinternationalmig|rdomesticmig|rnetmig)$", type))
  ) %>%
  mutate(
    value = as.integer(value),
    year = as.integer(year),
    type = case_when(
      type == "estimatesbase" ~ "estimate_base",
      type == "popestimate" ~ "estimate",
      type == "npopchg_" ~ "change",
      type == "naturalinc" ~ "natural_increase",
      type == "internationalmig" ~ "migration_international",
      type == "domesticmig" ~ "migration_domestic",
      type == "netmig" ~ "migration_net",
      TRUE ~ type
    ),
    type = factor(type)
  )

# Remove county name for state level data.
#
census <- census %>%
  mutate(
    county_name = ifelse(level == "state", NA, county_name),
    county_fips = ifelse(level == "state", NA, county_fips)
  )

# Change column order.
#
census <- census %>%
  select(
    level,
    region,
    division,
    fips,
    state_fips,
    county_fips,
    state_name,
    county_name,
    type,
    year,
    value
  )

usethis::use_data(census, overwrite = TRUE)

file.remove(RAWNAME)
