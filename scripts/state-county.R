library(dplyr)
library(readr)

# RAW DATA ------------------------------------------------------------------------------------------------------------

# Raw data are from https://github.com/kjhealy/fips-codes.

STATE_FIPS_CSV <- here::here("data-raw", "fips-master-state.csv")
COUNTY_FIPS_CSV<- here::here("data-raw", "fips-master-county.csv")

STATE_FIPS_URL <- "https://github.com/kjhealy/fips-codes/raw/master/state_fips_master.csv"
COUNTY_FIPS_URL <- "https://github.com/kjhealy/fips-codes/raw/master/county_fips_master.csv"

if (!file.exists(STATE_FIPS_CSV)) {
  download.file(STATE_FIPS_URL, STATE_FIPS_CSV)
}

if (!file.exists(COUNTY_FIPS_CSV)) {
  download.file(COUNTY_FIPS_URL, COUNTY_FIPS_CSV)
}

# FIPS ----------------------------------------------------------------------------------------------------------------

fips_state <- read_csv(
  STATE_FIPS_CSV,
  col_types = "ccciiiiicc"
) %>%
  select(-long_name) %>%
  select(fips_state = fips, everything())

# Manually add 'District of Columbia'.
#
fips_state <- fips_state %>%
  bind_rows(
    data.frame(
      fips_state = 11,
      state_name = 'District of Columbia',
      state_abbr = 'DC'
    )
  ) %>%
  arrange(fips_state)

fips_county <- read_csv(
  COUNTY_FIPS_CSV,
  col_types = "icccciiiiiccc"
) %>%
  mutate(
    fips_state = fips %/% 1000,
    fips_county = fips %% 1000
  ) %>%
  select(fips, fips_state, fips_county, everything())

usethis::use_data(fips_state, overwrite = TRUE)
usethis::use_data(fips_county, overwrite = TRUE)

# SSA -----------------------------------------------------------------------------------------------------------------

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

