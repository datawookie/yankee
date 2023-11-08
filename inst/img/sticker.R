library(hexSticker)

URL_FLAG_SVG = "https://raw.githubusercontent.com/hampusborgos/country-flags/master/svg/us.svg"
NAME_FLAG_SVG = "us_flag.svg"
NAME_FLAG_PNG = "us_flag.png"

if (!file.exists(NAME_FLAG_SVG)) {
  download.file(URL_FLAG_SVG, NAME_FLAG_SVG)
}

if (!file.exists(NAME_FLAG_PNG)) {
  system(paste("convert -resize 2000x", NAME_FLAG_SVG, NAME_FLAG_PNG))
}

sticker(
  NAME_FLAG_PNG,
  package = "{yankee}",
  p_y = 1.6,
  p_size = 20,
  p_color = "#000000",
  p_family = "sans",
  s_x = 1,
  s_y = 0.95,
  s_width = 0.85,
  h_color = "#000000",
  h_fill = "#FFFFFF"
)

