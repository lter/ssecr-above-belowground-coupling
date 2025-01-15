# -----------------------------------------------------------------------------#
# Cleaning and organizing downloaded NEON data
# Original Author: L. McKinley Nevins 
# January 15, 2024
# Software versions:  R v 4.4.1
#                     tidyverse v 2.0.0
#                     neonUtilities v 2.4.2
#                     ecocomDP v 1.3.1
#                     
# -----------------------------------------------------------------------------#

# PACKAGES, SCRIPTS, AND SETUP ####
library(tidyverse); packageVersion("tidyverse")
library(neonUtilities); packageVersion("neonUtilities")
library(ecocomDP); packageVersion("ecocomDP")

#################################################################################
#                               Main workflow                                   #
#  Explore the data structure of the various data products downloaded from      #
#  NEON. Figure out how to unpack all csv's and make nice stacked data files    #
#  that can then be matched up according to site-months to pair above and below.#
#                                                                               #
#################################################################################

########

# load in NEON token 

wd <- "~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/" # this will depend on your local machine
setwd(wd)

source(paste0(wd, "/neon_token_source.R"))

#################################################################################

# Starting with plant community data first 

# load in the two data files, one at 1m subplots, and one at 10m subplots 

# 1m subplot data 
plant_1m <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/A_COM_NEON_001.csv")

# 10 and 100 m subplot data 
plant_10m <- read.csv("~/Dropbox/WSU/SSECR/ssecr-above-belowground-coupling/A_COM_NEON_002.csv")




