# -----------------------------------------------------------------------------#
# Pull out Konza NEON data
# Original Author: L. McKinley Nevins 
# April 8, 2025
# Software versions:  R v 4.4.1
#                     tidyverse v 2.0.0
#                     dplyr v 1.1.4
#                     neonUtilities v 2.4.2
#                     ecocomDP v 1.3.1
#                     
# -----------------------------------------------------------------------------#

# PACKAGES, SCRIPTS, AND SETUP ####
library(tidyverse); packageVersion("tidyverse")
library(dplyr); packageVersion("dplyr")
library(neonUtilities); packageVersion("neonUtilities")
library(ecocomDP); packageVersion("ecocomDP")

#################################################################################
#                               Main workflow                                   #
#  Grab data from the two Konza NEON sites for both the plants and fungi and    #
#  make sure they are nice for preliminary analyses.                            #
#                                                                               #
#################################################################################


# plant community data 
plant <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/NEON_A_COM_species_x_site.csv")

# fungal community data 
fungi <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/NEON_ITS_COMP_species_x_site.csv")


######################

# Organizing 
# make site columns for both datasets 

plant <- tidyr::separate(plant, X, into = c("Site", "Month", "Year"), sep = "\\.")

# bit different for the fungal data names 

fungi <- fungi %>%
  mutate(
    Site = str_extract(X, "^[^_]+"),
    Sample_date = str_extract(X, "\\d{8}")
  )


fungi <- fungi %>%
  mutate(
    Year = substr(Sample_date, 1, 4),
    Month = substr(Sample_date, 5, 6),
    Day = substr(Sample_date, 7, 8)
  )

# all set as separate columns 


# now filter for the sites of interest: KONZ and KONA

#plants 
plant$Site <- as.factor(plant$Site)

# looks like some of the sites have a different numbering system, maybe reflecting subplots sampled 
# this isnt the case for KONZ or KONA so I'm leaving it alone for right now. 

# filter by site
KONZA_plant <- plant[plant$Site %in% c("KONZ", "KONA"), ]

#fungi 
fungi$Site <- as.factor(fungi$Site)

KONZA_fungi <- fungi[fungi$Site %in% c("KONZ", "KONA"), ]

# change the order of columns to make them nice for viewing 
KONZA_fungi <- KONZA_fungi %>%
  select(Site, Sample_date, Year, Month, everything())


# Identify metadata columns to keep
metadata_cols_plant <- c("Site", "Year", "Month")

metadata_cols_fungi <- c("Site", "Sample_date", "Year", "Month", "X")

# Remove all-zero species columns
plant_filtered <- KONZA_plant %>%
  select(all_of(metadata_cols_plant), where(~ any(. != 0)))


fungi_filtered <- KONZA_fungi %>%
  select(all_of(metadata_cols_fungi), where(~ any(. != 0)))



#save datasets 

# plants 
write.csv(plant_filtered, "~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/NEON_KONZA_plants.csv")

#fungi
write.csv(fungi_filtered, "~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/NEON_KONZA_fungi.csv")

