# Bureau of Economic Analysis (BEA) ----

# Retrieve data from the U.S. Department of Commerce's
# Bureau of Economic Analysis (BEA) with 
# its `bea.R` R package.

# The package is available on:
# - CRAN: https://cran.r-project.org/package=bea.R
# - GitHub: https://github.com/us-bea/bea.R


## Setup ----

# 1. Install the package from CRAN.
#   install.packages("bea.R")

# 2. Go to https://apps.bea.gov/API/signup/
#    and get your personal BEA API key.

# 3. Open your .Renviron file with
#     usethis::edit_r_environ()
#     and save your key as "BEA_API_KEY".

# 4. Restart R.

# 5. Check that your API key is recognized
Sys.getenv("BEA_API_KEY")

# 6. Save your BEA API key
beaKey <- Sys.getenv("BEA_API_KEY")

# 7. Load the `bea.R` package (and any other packages you may need)
library(tidyverse)
library(bea.R)


# The `bea.R` package offers two main methods:
# `beaSearch()` and `beaGet()`.


## beaSearch ----

# Use `bea.R::beaSearch()` to search for keywords:
beaSearch(searchTerm = "personal consumption", beaKey = beaKey)

# `bea.R::beaSearch()` currently only searches national and regional data.

# Specify `"asHtml = TRUE"` to view in-browser:j
beaSearch(searchTerm = "gross domestic", beaKey, asHtml = TRUE)


## beaGet ----

# `bea.R::beaGet()` lets you access the data once you
# have identified the TableID number with `bea.R::beaSearch()`.

# As an example we use the National Income and Production Accounts 
# (NIPA) table for 2015, with TableID no. 66.
beaSpecs <- list(
  "UserID" = beaKey,
  "Method" = "GetData",
  "datasetname" = "NIPA",
  "TableName" = "T20305",
  "Frequency" = "Q",
  "Year" = "X",
  "ResultFormat" = "json"
)

beaPayload <- beaGet(beaSpecs)

# To retrieve data for 2011-2015, use
# "Year" = "2011,2012,2013,2014,2015"

# The API documentation is available at
# https://apps.bea.gov/API/bea_web_service_api_user_guide.htm

# It includes information about the parameters required by
# `bea.R::beaGET()`.

# Setting `asWide = FALSE` gives results closest to the way
# they are actually returned by the BEA API
# (every column is a variable, every row is an observation)

beaLong <- beaGet(beaSpecs, asWide = FALSE)
head(beaLong)
# TableName, SeriesCode, LineNumber, LineDescription, TimePeriod,
# METRIC_NAME, CL_UNIT, UNIT_MULT, DataValue, NoteRef

# To return in a format in which each column represents a series,
# set `iTableStyle = FALSE`.

# This returns columns named with a concatenation of the descriptive
# column values, whereas rows are populated with numeric "DataValues"
# for each "TimePeriod", and it has one column named "TimePeriod"
# filled with dates.
beaStabTab <- beaGet(beaSpecs, iTableStyle = FALSE)

head(beaStabTab)

# By default, `asWide = TRUE` and `iTableStyle = TRUE`,
# as this format is the most similar to the BEA's iTables;
# the "beaPayload" object is the default format.


## beaViz ----

# The `bea.R` package includes an experimental method to create
# a visual dashboard.
# This method is still under development.

# It is designed to work with the standard R Console interface,
# and not with R Studio (!).

# If you want to experiment with `bea.R::beaViz()`,
# in R Studio, you click on "Open in Browser" at the top
# of the pop-up box after you execute the method.

# The `beaViz()` method allows you to pass a variable generated
# from `beaGet()` to create a dashboard.
beaViz(beaPayload)


# `beaViz()` is currently only available for use with the
# NIPA and NIUnderlyingDetail data sets and the associated meta data.


## beaSets ----

# `beaSets()` returns a list of all available data sets
bea_sets <- beaSets(beaKey)

bea_sets |> 
  as_tibble() |> 
  unnest(cols = c(Dataset)) |> 
  set_names(c("Name", "Description"))


## US GDP by major type of product ----

# Table T10202
# NIPA
# Table 1.2.2. Contributions to Percent Change in Real Gross Domestic Product 
# by Major Type of Product

beaSpecs <- list(
  "UserID" = beaKey,
  "Method" = "GetData",
  "datasetname" = "NIPA",
  "TableName" = "T10202",
  "Frequency" = "Q",
  "Year" = "ALL",
  "ResultFormat" = "json"
)

beaLong <- beaGet(beaSpecs, asWide = FALSE)

gdp_selection <- c(
  # "Gross domestic product",
  "Goods",
  "Services",
  "Structures",
  "Motor vehicle output"
)

beaLong |> 
  as_tibble() |> 
  select(TimePeriod, LineDescription, DataValue) |> 
  filter(LineDescription %in% gdp_selection) |> 
  rename(
    date = TimePeriod,
    product = LineDescription,
    value = DataValue
  ) |> 
  mutate(
    date = as_date(date, format = "%YQ%q")
  ) |> 
  ggplot(mapping = aes(x = date, y = value, color = product)) +
  geom_line(lwd = 1) +
  scale_x_date(date_breaks = "10 years", date_labels = "%Y") +
  scale_y_continuous(breaks = seq(from = -10, to = 10, by = 5), limits = c(-10, 10)) +
  labs(
    title = "Contributions to % Change in Real Gross Domestic Product\nby Major Type of Product",
    subtitle = "",
    caption = "",
    x = "Date",
    y = "US Monthly CPI (%)"
  ) +
  theme_bw() +
  theme(legend.position = "top")

ggsave(filename = "01_us-gdp-quarterly-products", device = "png", path = "figures/", height = 4, width = 8)
graphics.off()

# END