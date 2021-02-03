library(readr)

fips_state <- read_csv(
  here::here("data-raw", "state-fips-master.csv"),
  col_types = "ccciiiiicc"
) %>%
  select(-long_name) %>%
  select(fips_state = fips, everything())

fips_county <- read_csv(
  here::here("data-raw", "county-fips-master.csv"),
  col_types = "icccciiiiiccc"
) %>%
  mutate(
    fips_state = fips %/% 1000,
    fips_county = fips %% 1000
  ) %>%
  select(fips, fips_state, fips_county, everything())

usethis::use_data(fips_state, overwrite = TRUE)
usethis::use_data(fips_county, overwrite = TRUE)
