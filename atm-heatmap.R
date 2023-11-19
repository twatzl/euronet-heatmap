install.packages("osmdata")
install.packages("leaflet")
install.packages("leaflet.extras")
install.packages("sf")

library(osmdata)
library(leaflet)
library(leaflet.extras)
library(sf)

# Function to geocode city name and get bounding box
get_bbox_from_city <- function(city_name) {
  bbox <- osmdata::getbb(city_name)
  return(bbox)
}

create_atm_heatmap <- function(city_name) {
  # Get bounding box for the specified city
  bbox <- get_bbox_from_city(city_name)
  
  # Download OpenStreetMap data for the specified area and filter atm_nodes with amenity=atm and brand="Euronet"
  atm_osm_data <- opq(bbox = bbox, timeout = 25) %>%
    add_osm_feature(key = "amenity", value = "atm") %>%
    add_osm_feature(key = "brand", value = "Euronet") %>%
    osmdata_sf()
  
  # Extract atm_nodes from the osmdata object
  atm_nodes <- atm_osm_data$osm_points
  
  if (length(atm_nodes$geometry) == 0) {
    print("no atms found")
    return()
  }
  
  # Download administrative boundary data for the specified area
  admin_boundaries <- opq(bbox = bbox, timeout = 25) %>%
    add_osm_feature(key = "boundary", value = "administrative") %>%
    add_osm_feature(key = "admin_level", value = 1:8) %>%
    osmdata_sf()
  
  admin_boundaries <- admin_boundaries$osm_lines
  
  # Extract latitude and longitude from the geometry column
  atm_nodes$lon <- sf::st_coordinates(atm_nodes)[, "X"]
  atm_nodes$lat <- sf::st_coordinates(atm_nodes)[, "Y"]
  
  missing_values <- atm_nodes$lon %in% c(NA, NULL) | atm_nodes$lat %in% c(NA, NULL)
  
  # Filter out rows with missing or NULL values
  atm_nodes <- atm_nodes[!missing_values, ]
  
  # Create a leaflet map and add a heatmap layer
  leaflet(atm_nodes) %>%
    addTiles() %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    fitBounds(bbox["x", "min"], bbox["y","min"], bbox["x","max"], bbox["y","max"]) %>%
    addHeatmap(
      data = atm_nodes,    
      lng = ~lon,
      lat = ~lat,
      max = 1,
      radius = 15, # Adjust the radius as needed
      blur = 10   # Adjust the blur as needed
    ) %>%
    addPolylines(data = admin_boundaries, color = "darkgray", weight = 2)
}


# Specify the city name
# do not enter countries, it will crash R
city_name <- "Praha"
create_atm_heatmap(city_name)

