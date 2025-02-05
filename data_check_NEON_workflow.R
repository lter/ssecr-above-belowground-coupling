# -----------------------------------------------------------------------------#
# Check and clean downloaded NEON data
# Original Author: L. McKinley Nevins 
# February 5, 2025
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
#  Follow the recommended workflow from NEON to check the data. This is looking #
#  for things like duplicate records, and organizing taxa into a taxon table,   #
#  etc. Not sure these steps will be applicable to all data files.              #
#                                                                               #
#################################################################################

# Following the workflow described here for processing NEON biodiversity data: 
# https://www.neonscience.org/resources/learning-hub/tutorials/neon-biodiversity-ecocomdp-cyverse


########

# load in NEON token 

wd <- "~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/" # this will depend on your local machine
setwd(wd)

source(paste0(wd, "/neon_token_source.R"))

#################################################################################
# PLANT COMMUNITY DATA

# load in the two data files, one at 1m subplots, and one at 10m subplots 

# 1m subplot data - percent cover data 
plant_1m <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/A_COM_NEON_001.csv")

# 10 and 100 m subplot data - presence/absence data 
plant_10m <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/A_COM_NEON_002.csv")

#check variables list 
plant_meta <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/A_COM_NEON_001.2_meta.csv")

## Not doing any other prior cleaning, just following the recommended steps: 

  ## notes are a mix of my own and existing from the lesson materials 
  ## the lesson originally used invertebrate data 

  ## removing the section of checking for duplicate records, they did this for the invert data due 
  ## to some issues with this historically 

# expand dates, into new columns

plant_1m <- plant_1m %>% 
  tidyr::separate_wider_delim(cols = endDate, 
                              delim = "-",
                              names = c("Year", "Month", "Day"),
                              cols_remove = FALSE)


# extract location data into a separate table
table_location_plant_1m <- plant_1m %>%
  # keep only the columns listed below
  select(siteID, 
         domainID,
         namedLocation, 
         decimalLatitude, 
         decimalLongitude, 
         elevation) %>%
  # keep rows with unique combinations of values, 
  # i.e., no duplicate records
  distinct()



# create a taxon table, which describes each 
# taxonID that appears in the data set

table_taxon_plant_1m <- plant_1m %>%
  # keep only the columns listed below
  select(taxonID, taxonRank, scientificName,
         family, identificationQualifier,
         identificationReferences) %>%
  # remove rows with duplicate information
  distinct()


# taxon table information for all taxa in 
# our database can be downloaded here:
# takes 1-2 minutes

 full_taxon_table_from_api <- 
   neonOS::getTaxonList(
     "PLANT", 
     token = Sys.getenv("NEON_TOKEN"))


# Make the observation table.
# check for repeated taxa within a sampleID that need to be added together
 
    ## Maybe use eventID here? 

taxonomyProcessed_summed_plant_1m <- plant_1m %>% 
  select(eventID,
         taxonID,
         percentCover,
         heightPlantSpecies) %>%
  group_by(eventID, taxonID) %>%
  summarize(
    across(c(percentCover, heightPlantSpecies), ~sum(.x, na.rm = TRUE)))


# join summed taxon counts back with sample and field data
table_observation_plant_1m <- taxonomyProcessed_summed_plant_1m %>%
  # Join relevant sample info back in by eventID
  left_join(plant_1m %>% 
              select(eventID,
                     domainID,
                     siteID,
                     namedLocation,
                     Year, Month, Day,
                     endDate,
                     taxonID,
                     family, 
                     scientificName,
                     taxonRank) %>%
              distinct())



# check for duplicate records, should return a table with 0 rows

table_observation_plant_1m %>% 
  group_by(eventID, taxonID) %>% 
  summarize(n_obs = length(eventID)) %>%
  filter(n_obs > 1)

# this has a lot of "duplicates" because there were multiple plots sampled for each 
# "event", so a plant can appear multiple times if it was recorded in different plots. 
# the plot is provided int he namedLocation, so I think this is okay. They could
# be summed by species further in the future if we desired. 

# extract sample info
table_sample_info_plant_1m <- table_observation_plant_1m %>%
  select(eventID, domainID, siteID, namedLocation, 
         endDate, Year, Month, Day,
         percentCover, heightPlantSpecies) %>%
  distinct()

# not sure how useful this particular table is 

# create an occurrence summary table
taxa_occurrence_summary_plant_1m <- table_observation_plant_1m %>%
  select(eventID, taxonID) %>%
  distinct() %>%
  group_by(taxonID) %>%
  summarize(occurrences = n())

# just occurrences across all of the plots. Also not super useful for us perhaps 


## Some exploratory visualizations 

# no. taxa by rank by site
table_observation_plant_1m %>% 
  group_by(domainID, siteID, taxonRank) %>%
  summarize(
    n_taxa = taxonID %>% 
      unique() %>% length()) %>%
  ggplot(aes(n_taxa, taxonRank)) +
  facet_wrap(~ domainID + siteID) +
  geom_col()

# lots of sites, so it's a lot to look at 

## Create a site x species table 

# select only site by species density info and remove duplicate records
table_sample_by_taxon_density_long_plant_1m <- table_observation_plant_1m %>%
  select(eventID, taxonID, percentCover) %>%
  distinct() %>%
  # filter out NA's in any of the columns 
  # pivoting wider down below can't be done if there are missing cases in the 
  # eventID column 
  filter(!is.na(percentCover)) %>%
  filter(!is.na(eventID)) %>%
  filter(!is.na(taxonID))

# this results in 50,238 rows, where each row is a complete observation of 
# a taxon with percent cover for a given sampling event at a site 


# pivot to wide format, sum multiple counts per eventID

table_sample_by_taxon_density_wide_plant_1m <- table_sample_by_taxon_density_long_plant_1m %>%
  tidyr::pivot_wider(id_cols = eventID, 
                     names_from = taxonID,
                     values_from = percentCover,
                     values_fill = list(percentCover = 0),
                     values_fn = list(percentCover = sum)) %>%
  column_to_rownames(var = "eventID") 


# check col and row sums -- mins should all be > 0

colSums(table_sample_by_taxon_density_wide_plant_1m) %>% min()
## [1] 0

rowSums(table_sample_by_taxon_density_wide_plant_1m) %>% min()
## [1] 0.5

# This results in a species x site matrix for all of the NEON sites. 
# the rows are the event ID, which comprise the site and year 



# Example: use wide format data with functions in vegan
# load library

library(vegan)

# calculate pairwise dissimilarities
data_dist <- vegdist(table_sample_by_taxon_density_wide_plant_1m, method = "bray")

# view histogram of dissimilarity values in the dataset
hist(data_dist, xlab = "Bray-Curtis dissimilarity")
