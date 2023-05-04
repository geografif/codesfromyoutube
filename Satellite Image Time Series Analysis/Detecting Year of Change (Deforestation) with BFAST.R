library(raster)
library(rasterVis)
library(stringr)
library(zoo) # time series handling
library(strucchange) # break detection
library(colorspace)
devtools:::install_github("gearslaboratory/gdalUtils")
devtools:::install_github('loicdtx/bfastSpatial')
library(gdalUtils)
library(bfastSpatial)
#library(bfast)

getwd()
setwd("/home/jovyan/private/TimeSeries/OP/NBR")

# -------------------------------------
# Data Preparation
# -------------------------------------

# Load Landsat 7 & 8
setwd("D:/MSc/ITC/Course/TimeSeries/TimeSeries_Practical/08_Project/NBR_gapfill/L8")
listlandsat78 = list.files(pattern='.tif$', all.files=TRUE, full.names=FALSE)
landsatNBR_78 = stack(listlandsat78)
listlandsat78 = str_sub(listlandsat78, start=17, end=24) #select date from filename string
listdate78 = as.Date(listlandsat78, "%Y%m%d")
sorted_date78 = order(listdate78)
listname78 = paste("NBR.", listlandsat78,  sep="")
names(landsatNBR_78) = listname78
landsatNBR_78 = setZ(landsatNBR_78, listdate78, "dates")
landsatNBR_78 = landsatNBR_78[[sorted_date78]]
plot(landsatNBR_78)

# Load Landsat 5
setwd("D:/MSc/ITC/Course/TimeSeries/TimeSeries_Practical/08_Project/NBR_gapfill/L5")
listlandsat5 = list.files(pattern='.tif$', all.files=TRUE, full.names=FALSE)
landsatNBR_5 = stack(listlandsat5)
listlandsat5 = str_sub(listlandsat5, start=15, end=22) #select date from filename string
listdate5 = as.Date(listlandsat5, "%Y%m%d")
sorted_date5 = order(listdate5)
listname5 = paste("NBR.", listlandsat5,  sep="")
names(landsatNBR_5) = listname5
landsatNBR_5 = setZ(landsatNBR_5, listdate5, "dates")
landsatNBR_5 = landsatNBR_5[[sorted_date5]]
plot(landsatNBR_5)

# Combine and reorder layers
setwd("D:/MSc/ITC/Course/TimeSeries/TimeSeries_Practical/08_Project/")
listdate = c(listdate5, listdate78)
sorted_date = order(listdate)
landsatNBR = stack(landsatNBR_5, landsatNBR_78)
landsatNBR = landsatNBR_78
listdatex = listdate[sorted_date]
landsatNBR = setZ(landsatNBR, listdatex, "dates")
print(landsatNBR)
print(landsatNBR$NBR.20000108)
plot(landsatNBR)

# -------------------------------------
# Create monthly average (if needed)
# -------------------------------------
listdatemonth = format((listdatex), format = "%Y-%m")
listdatemonth = as.numeric(listdatemonth)
#https://gis.stackexchange.com/questions/237272/mean-by-month-on-r-stacked-raster

# monthly averaging
#monthlyNBR<- stackApply(landsatNBR, listdatemonth, fun = mean)


# -------------------------------------
# Change detection using bfastSpatial
# -------------------------------------
# You will begin with BFAST by extracting a MODIS time series for a single pixel. T
# his will help you to better understand time series decomposition and 
# how BFAST breaks down a time series by gradual and abrupt changes (trends/cycles), 
# as well as short-term fluctuations (seasonality). 
# You will use BFASTmonitor to do this. 
# BFASTmonitor is essentially a spatial subroutine of BFAST. 

#A time series for a single pixel can be extracted with click(). This can be seen with the following commands. The first command plots the first layer in the MODIS time series. The second command creates crosshairs. Use these crosshairs to select a pixel on the plot. 
#The time series for that pixel is stored in the variable VI.

#collect pixel value with click
#rm(landastNBR)
#landsatNBR = landsatNBR_78
plot(landsatNBR, 4) #layer n
vi = as.numeric(click(landsatNBR, n = 1))#/10000 #click a pixel on the plot, then run the next lines

#We have to convert it to a time series before we can plot it conveniently. 
#This is done with ts(). The time series begins in April (4th month) 2000. 
#There are 23 time steps in a year.
vi = ts(vi, start = c(2000, 1), frequency = 23) #f =23
plot(vi, ylab = "VI", type = "o")

#You can probably see some interannual variations in the time series, but there are a number of gaps, mainly caused by cloud cover. 
#These could be filled, so that fluctuations are properly detected. There is a trade-off however, since decomposing gap-filled data runs the risk of explaining modelled (instead of) actual changes. The following code runs BFASTmonitor for the given time series. 
#It arbitrarily puts a “break” (abrupt change) in January 2010 to better understand how they are detected.
bfm = bfastmonitor(vi, start = c(2004,1), history='all')
#bfm = bfast01(vi)
plot(bfm, ylab = "VI")

#The period before the break indicated by the blue line is the historical (reference) period. The red line shows the monitoring period or the subset of the time series after the break. In this case, no break was detected. A break would be detected if the change after the time of the break (termed break point) was significantly different from before the break. The break point can be found by typing bfm$breakpoint in the command line. In this case, it returns NA, because no break point was detected. bfm$magnitude returns the magnitude of the change. 
#You can get more information on the model fit by typing the bfm variable in the command line and the summary() function.
#The following function applies BFASTmonitor on a pixel basis over an entire image. It can take some minutes to run. It returns the breakpoint and magnitude. The breakpoint and magnitude are rasterized in the following lines.

#landbrick = brick(landsatNBR)
bfmx <- bfmSpatial(landsatNBR, start=c(2004, 1), order=1)
change <- raster(bfmx, 1)
plot(change, main="Change Year", colNA="black")


# -------------------------------------
# Display change at month level
# -------------------------------------

monthly_change <- changeMonth(changeRaster) 

# set up labels and colourmap for months
monthlabs <- c("jan", "feb", "mar", "apr", "may", "jun", 
               "jul", "aug", "sep", "oct", "nov", "dec")
cols <- rainbow(12)
plot(monthly_change, col=cols, breaks=c(1:12), legend=FALSE)
# insert custom legend
legend("bottomright", legend=monthlabs, cex=0.5, fill=cols, ncol=2)


# -------------------------------------
# Reclassify result to year level
# -------------------------------------
#changeRaster = raster("D:/MSc/ITC/Course/TimeSeries/TimeSeries_Practical/08_Project/NBR_gapfill/Rbfast_ChangeYear.tif")
#plot(changeRaster)

#rc <- reclassify(changeRaster, c(2011,2011.99,2011, 2012,2012.99,2012, 2013,2013.99,2013, 2014,2014.99,2014, 2015,2015.99,2015, 2016,2016.99,2016, 2017,2017.99,2017, 2018,2018,99,2018, 2019,2019.99,2019))

changeRaster[changeRaster < 2012] <- 2011
changeRaster[changeRaster < 2013 & changeRaster > 2012] <- 2012
changeRaster[changeRaster < 2014 & changeRaster > 2013] <- 2013
changeRaster[changeRaster < 2015 & changeRaster > 2014] <- 2014
changeRaster[changeRaster < 2016 & changeRaster > 2015] <- 2015
changeRaster[changeRaster < 2017 & changeRaster > 2016] <- 2016
changeRaster[changeRaster < 2018 & changeRaster > 2017] <- 2017
changeRaster[changeRaster < 2019 & changeRaster > 2018] <- 2018
changeRaster[changeRaster < 2020 & changeRaster > 2019] <- 2019

writeRaster(changeRaster, filename="Rbfast_ChangeYear_reclass", format="GTiff")


# -------------------------------------
# Change detection using regular bfast
# -------------------------------------

#////////////////////
f_bfm = function(x) {
  x = ts(x, start = c(2000, 1), frequency = 23)
  bfm = bfastmonitor(data = x, start = c(2004, 1))
  return(cbind(bfm$breakpoint, bfm$magnitude))
}
rbfm               = calc(landsatNBR, fun = function(x) {t(apply(x, 1, f_bfm))}) 
timeofbreak        = raster(rbfm, 1)
magnitudeofbreak   = raster(rbfm, 2)
magnitudeofbreak[is.na(timeofbreak)] = NA # only visualise the magnitude of the detected breaks
plot(magnitudeofbreak, zlim = c(-0.2, 0.2), col = rev(diverge_hcl(7))) #plots the magnitude of break
plot(timeofbreak, colNA = "black") #plots the breakpoint
#Visualize the magnitude and breakpoint (timing) images side-by-side. 
#Where do you see positive and negative change? 
#What years do these changes occur? 
#How you explain the patterns you see?

#As before, you can click on pixels in the magnitude image to view time series 
#with actual detected breaks.
x = as.numeric(click(modis, n = 1))/10000
ndvi = ts(x, start = c(2002, 1), frequency = 23)
bfm = bfastmonitor(ndvi, start = c(2010, 1))
plot(bfm, ylab = "VI")
#Click on various positive (blue) and negative (red) breaks. 
#What do you observe in terms of the time series before and after the breakpoint> 
#Do the timing of the breaks in the time series plot correspond with 
#the breakpoint image? 
#Do you see any other patterns?
