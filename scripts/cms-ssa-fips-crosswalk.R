library(readr)
library(janitor)
library(dplyr)

# NOTES:
#
# 1. Run the fips-create.R script first.

# Get full set of SSA codes used in CMS data.
#
# These are from the CMS Extracts "claimsk" files.
#
cms_ssa <- read_delim(
  here::here("data-raw", "cms-ssa-codes.csv"),
  delim = ";",
  col_types = "cc"
) %>%
  mutate(
    ssa = as.integer(paste0(ssa_state, ssa_county))
  ) %>%
  select(ssa)

ssa_fips <- read_csv(
  here::here("data-raw", "ssa-fips-crosswalk-2018.csv"),
  col_types = "cciiic"
) %>%
  clean_names() %>%
  select(
    ssa = ssacd,
    fips = fips_county_code
  )

ssa_state <- read_delim(
  here::here("data-raw", "ssa-state.csv"),
  delim = ";",
  col_types = "ic"
)

ssa_county <- cms_ssa %>%
  left_join(ssa_fips, by = "ssa") %>%
  mutate(
    ssa_state = as.integer(ssa %/% 1000),
    ssa_county = as.integer(ssa %% 1000)
  )

ssa_county <- ssa_county %>%
  left_join(fips_county, by = "fips") %>%
  select(
    ssa,
    matches("^ssa_"),
    fips,
    matches("^fips_"),
    county_name
  ) %>%
  unique()

ssa_state <- ssa_state %>%
  left_join(
    ssa_county %>%
      select(ssa_state, fips_state) %>%
      na.omit() %>%
      unique(),
    by = "ssa_state"
  ) %>%
  left_join(fips_state %>% select(-state_name), by = "fips_state") %>%
  select(ssa_state, fips_state, state_name, state_abbr)

usethis::use_data(ssa_state, overwrite = TRUE)
usethis::use_data(ssa_county, overwrite = TRUE)
