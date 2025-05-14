# -----------------------------------------------------------------------------#
# Mapping LTER and NEON sites
# Original Author: L. McKinley Nevins 
# March 31, 2025
# Software versions:  R v 4.4.1
#                     ggplot2 v 3.5.1
#                     maps v 3.4.2.1
#                     sf v 1.0.19
#                     ggspatial v 1.1.9
#
# -----------------------------------------------------------------------------#

# PACKAGES, SCRIPTS, AND SETUP ####
library(ggplot2); packageVersion("ggplot2")
library(maps); packageVersion("maps")
library(sf); packageVersion("sf")
library(ggspatial); packageVersion("ggspatial")

#################################################################################
#                               Main workflow                                   #
#  Load in site coordinates for LTER and NEON sites from which we currently     #
#  have suitable data sets. Map sites onto map of the US and Puerto Rico.       #
#                                                                               #
#################################################################################

coords <- read.csv("./coords.csv")

# Get US boundaries
us <- ne_states(country = "United States of America", returnclass = "sf")

# Convert points to sf
coords_sf <- st_as_sf(coords, coords = c("lon", "lat"), crs = 4326)

# Plot
map <- ggplot() +
  geom_sf(data = us, fill = "lightgray", color = "white") +
  geom_sf(data = coords_sf, aes(color = site_type), size = 2.5) +
  coord_sf(xlim = c(-170, -60), ylim = c(15, 70)) +  
  annotation_scale(location = "bl", width_hint = 0.2) +  # Scale bar
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering) +  # North arrow
  theme_bw() +
  scale_color_manual(values = c(
    "LTER" = "darkorange2",
    "NEON" = "purple4",
    "Co-Located" = "lightblue"
  )) +
  theme(legend.position.inside = c(1,0.15), 
        legend.background = element_rect(fill = "white", color = "black", linewidth = 0.5)) +  # Legend placement
  labs(color = "Sites")  # Legend title

map
