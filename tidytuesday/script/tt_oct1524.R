# load libraries
library(tidyverse)
library(ggmap)

orcas <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-15/orcas.csv')

# Register your Google API Key
register_google(key = "YOUR_API_KEY_HERE")

# Get a base map
location <- c(lon = -124, lat = 48.5) # Center point
base_map <- get_map(location, zoom = 7)

# Create Heat Map
ggmap(base_map) +
    geom_density2d(data = orcas_data, aes(x = longitude, y = latitude), size = 0.5) +
    stat_density2d(data = orcas_data, aes(x = longitude, y = latitude, fill = ..level..), geom = "polygon", alpha = 0.5) +
    scale_fill_viridis_c() +
    labs(title = "Orca Encounter Heat Map", x = "Longitude", y = "Latitude")


# Get a base map
location <- c(lon = -124, lat = 48.5) # Center point
base_map <- get_map(location, zoom = 7) # Adjust zoom as needed

