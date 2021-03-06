RemoteSensing_public <- list( #      *********** public *********************************

  initialize = function(url, userpwd=NULL, ssl_verifypeer=TRUE) {
    splitIndex <- regexpr(":", userpwd)
    if(splitIndex <= 0) {
      stop("parameter 'userpwd' is not of format: USER:PASSWORD")
    }
    user <- substring(userpwd, 0, splitIndex - 1)
    password <- substring(userpwd, splitIndex + 1)
    private$rsdbConnector <- RsdbConnector$new(base_url = url, username = user, password = password, ssl_verifypeer = ssl_verifypeer)
    
    private$base_url <- url
    test_url <- paste0(private$base_url, "/pointdb/")
    private$curlHandle <- RCurl::getCurlHandle()
    if(isUnauthorized(test_url, private$curlHandle)) { # only set AUTH_DIGEST if needed, if AUTH_DIGEST is set if not needed HTTP POST content will not be sent!
      #print("set userpwd with AUTH_DIGEST")
      private$curlHandle <- RCurl::getCurlHandle(httpauth = RCurl::AUTH_DIGEST, userpwd = userpwd, verbose = FALSE)
    }
    if(isUnauthorized(test_url, private$curlHandle)) { # only set AUTH_BASIC if needed, if AUTH_BASIC is set if not needed HTTP POST content will not be sent!
      #print("set userpwd with AUTH_BASIC")
      private$curlHandle <- RCurl::getCurlHandle(httpauth = RCurl::AUTH_BASIC, userpwd = userpwd, verbose = FALSE)
    }    
    responesHeader <- RCurl::url.exists(test_url, .header = TRUE, curl = RCurl::dupCurlHandle(private$curlHandle))
    #print(responesHeader)
    #print(responesHeader["status"])
    if(is.logical(responesHeader) && !responesHeader) {
      stop("No Connection to Remote Sensing Database.")
    }
    if(as.integer(as.integer(responesHeader["status"])/100) != 2) {
      stop("no connection to Remote Sensing Database: ",private$base_url, "    ", responesHeader["status"], "  ", responesHeader["statusMessage"])
    }
  },

  lidar = function(layer) {
    pointdb <- PointDB$new(private$base_url, layer, curlHandle=private$curlHandle, rsdbConnector = private$rsdbConnector)
    return(pointdb)
  },

  pointdb = function(name) {
    pointdb <- PointDB$new(private$base_url, name, curlHandle=private$curlHandle, rsdbConnector = private$rsdbConnector)
    return(pointdb)
  },

  rasterdb = function(name) {
    rasterdb <- RasterDB$new(private$base_url, name, curlHandle=private$curlHandle, rsdbConnector = private$rsdbConnector)
    return(rasterdb)
  },

  lidar_layers = function() {
    #dbs <- query_json(paste0(private$base_url, "/pointdb"), "dbs.json", curlHandle=private$curlHandle)
    result <- private$rsdbConnector$GET("/pointdb/dbs.json")
    return(result)
  },

  web = function() {
    #web_url <- paste0(private$base_url, "/web")
    web_url <- paste0(private$rsdbConnector$private$base_url, "/web")
    browseURL(web_url)
  },

  poi_group = function(group_name) {
    #group <- query_json(paste0(private$base_url, "/api"), "poi_group", c(name=group_name), curlHandle=private$curlHandle)
    group <- private$rsdbConnector$GET("/api/poi_group", list(name=group_name))
    row.names(group) <- group$name
    #names(group$x) <- group$name # does not apply names
    #names(group$y) <- group$name # does not apply names
    return(group)
  },

  poi = function(group_name, poi_name) {
    group <- self$poi_group(group_name)
    df <- group[group$name==poi_name,]
    if(nrow(df)<1) {
      stop("named point in POI-group '",group_name,"' not found: ", poi_name)
    }
    p <- as.list(df)
    return(p)
  },

  roi_group = function(group_name) {
    #group <- query_json(paste0(private$base_url, "/api"), "roi_group", c(name=group_name), curlHandle=private$curlHandle)
    group <- private$rsdbConnector$GET("/api/roi_group", list(name=group_name))
    row.names(group) <- group$name
    names(group$polygon) <- group$name
    return(group)
  },

  roi = function(group_name, roi_name) {
    group <- self$roi_group(group_name)
    df <- group[group$name==roi_name,]
    if(nrow(df)<1) {
      stop("named point in ROI-group '",group_name,"' not found: ", roi_name)
    }
    p <- as.list(df)
    return(p)
  },

  create_rasterdb = function(name) {
    #result <- query_json(paste0(private$base_url, "/api"), "create_raster", c(name=name), curlHandle=private$curlHandle)
    result <- private$rsdbConnector$GET("/api/create_raster", list(name=name))
    return(result)
  },

  pointcloud = function(name) {
    return(PointCloud$new(private$base_url, name, curlHandle = private$curlHandle, rsdbConnector = private$rsdbConnector))
  }

)

RemoteSensing_active <- list( #      *********** active *********************************

  roi_groups = function() {
    #groups <- query_json(paste0(private$base_url, "/api"), "roi_groups", curlHandle=private$curlHandle)
    groups <- private$rsdbConnector$GET("/api/roi_groups")
    return(groups)
  },

  poi_groups = function() {
    #groups <- query_json(paste0(private$base_url, "/api"), "poi_groups", curlHandle=private$curlHandle)
    groups <- private$rsdbConnector$GET("/api/poi_groups")
    return(groups)
  },

  pointdbs = function() {
    #dbs <- query_json(paste0(private$base_url, "/pointdb"), "dbs.json", curlHandle=private$curlHandle)
    dbs <- private$rsdbConnector$GET("/pointdb/dbs.json")
    return(dbs)
  },

  rasterdbs = function() {
    #meta <- query_json(private$base_url, "rasterdbs.json", curlHandle=private$curlHandle)
    meta <- private$rsdbConnector$GET("/rasterdbs.json")
    return(meta$rasterdbs)
  },

  pointclouds = function() {
    #json <- query_json(private$base_url, "pointclouds", curlHandle=private$curlHandle)
    json <- private$rsdbConnector$GET("/pointclouds")
    return(json$pointclouds)
  }

)

RemoteSensing_private <- list( #      *********** private *********************************

  base_url = NULL,
  curlHandle = NULL,
  rsdbConnector = NULL

)

#' RemoteSensing class
#'
#' Remote sensing database manages (hyperspectral) \strong{rasters} and (LiDAR) \strong{point-clouds}
#' as well as auxiliary ROIs (regions of interest as named polygons) and POIs (points of interest as named points).
#'
#' Objects of RemoteSensing class encapsulate connections to one remote sensing database.
#'
#' @docType class
#' @export
#' @author woellauer
#' @seealso \link{RasterDB} \link{PointCloud} \link{PointDB}
#'
#' @format
#' RemoteSensing \code{\link{R6Class}} object.
#'
#' Instance objects of R6Class are created by 'new':
#'
#' \code{remotesensing <- RemoteSensing$new(url, userpwd=NULL)}
#'
#' Methods of instance objects are called by '$':
#'
#' \code{result <- remotesensing$method(parameters)}
#'
#' @usage
#' remotesensing <- RemoteSensing$new(url, userpwd=NULL)
#'
#' remotesensing$rasterdbs
#' remotesensing$rasterdb(name)
#' remotesensing$create_rasterdb(name)
#'
#' remotesensing$pointclouds
#' remotesensing$pointcloud(name)
#'
#' remotesensing$pointdbs
#' remotesensing$pointdb(name)
#'
#' remotesensing$roi_groups
#' remotesensing$roi_group(name)
#' remotesensing$roi(group_name, roi_name)
#'
#' remotesensing$poi_groups
#' remotesensing$poi_group(name)
#' remotesensing$poi(group_name, poi_name)
#'
#' remotesensing$web()
#'
#' @section Methods:
#'
#' \describe{
#'
#' \item{RemoteSensing$new(url, userpwd=NULL)}{Open Remote Sensing Database.
#'
#' url: url of server. (local e.g. "http://localhost:8081" or remote e.g. "http://example.com:8081")
#'
#' userpwd: optional authentication (format: "user:password")
#'
#' returns: RemoteSensing object}
#'
#' \item{$rasterdbs}{get names of RasterDBs contained in Remote Sensing Database.}
#'
#' \item{$rasterdb(name)}{get RasterDB by name.}
#'
#' \item{$create_rasterdb(name)}{creates new empty RasterDB.
#'
#' returns: success message}
#'
#' \item{$pointclouds}{get names of PointClouds contained in Remote Sensing Database.}
#'
#' \item{$pointcloud(name)}{get PointCloud by name.}
#'
#' \item{$pointdbs}{get names of PointDBs contained in Remote Sensing Database.}
#'
#' \item{$pointdb(name)}{get PointDB by name.}
#'
#' \item{$roi_groups}{get names of ROI-groups.
#'
#' returns: data.frame of name and description}
#'
#' \item{$roi_group(name)}{get ROI-group by name.
#'
#' returns: data.frame of ROI-name and polygon}
#'
#' \item{$roi(group_name, roi_name)}{get one ROI.
#'
#' returns: polygon}
#'
#' \item{$poi_groups}{get names of POI-groups.
#'
#' returns: data.frame of name and description}
#'
#' \item{$poi_group(name)}{get POI-group by name.
#'
#' returns: data.frame of POI-name and position}
#'
#' \item{$poi(group_name, poi_name)}{get one POI.
#'
#' returns: position}
#'
#' \item{$web()}{Open web interface in browser.}
#' }
#'
#' @section ROI:
#' Region of interest (ROI) is a named polygon.
#'
#' Matrix of one row per polygon vertex and two columns with x- and y-coordinates describe the polygon.
#'
#' First and last vertex need to be same (a closed polygon).
#'
#' example:
#' \preformatted{
#' # get one ROI
#' roi <- remotesensing$roi(group_name="kili_A", roi_name="cof3_A")
#'
#' # get name of ROI
#' roi$name
#'
#' # get matrix of points
#' roi$polygon[[1]]
#' }
#'
#' @section POI:
#' Point of interest (POI) is a named point.
#'
#' example:
#' \preformatted{
#' # get one POI
#' poi <- remotesensing$poi(group_name="kili", poi_name="cof3")
#'
#' # get name of ROI
#' poi$name
#'
#' # get x-coodinate of POI
#' poi$x
#'
#' # get y-coodinate of POI
#' poi$y
#' }
#'
#' @examples
#' # open remote sensing database
#' library(rPointDB)
#' # remotesensing <- RemoteSensing$new("http://localhost:8081", "user:password") # local
#' remotesensing <- RemoteSensing$new("http://example.com:8081", "user:password") # remote server
#'
#' # get names of RasterDBs
#' remotesensing$rasterdbs
#'
#' # get one rasterdb
#' rasterdb <- remotesensing$rasterdb("kili_campaign1")
#'
#' # get names of PointDBs
#' remotesensing$pointdbs
#'
#' # get one pointdb
#' pointdb <- remotesensing$pointdb("kili")
#'
#' # get names of ROI groups
#' remotesensing$roi_groups
#'
#' # get one ROI group
#' rois <- remotesensing$roi_group("kili_A")
#'
#' # get one ROI
#' roi <- remotesensing$roi(group_name="kili_A", roi_name="cof3_A")
#'
#' # get names of POI groups
#' remotesensing$poi_groups
#'
#' # get one POI group
#' pois <- remotesensing$poi_group("kili")
#'
#' # get one POI
#' poi <- remotesensing$poi(group_name="kili", poi_name="cof3")
#'
#' # create extent around POI of 10 meter edge length
#' ext <- extent_diameter(poi$x, poi$y, 10)
#'
#' # get RasterStack of all bands at ext
#' r <- rasterdb$raster(ext)
#'
#' # get data.frame of LiDAR points at ext
#' df1 <- pointdb$query(ext)
#'
#' #get data.frame of LiDAR points at polygon ROI
#' df2 <- pointdb$query_polygon(roi$polygon[[1]])
#'
#' # open web interface in browser
#' remotesensing$web()
#'
RemoteSensing <- R6::R6Class("RemoteSensing",
                          public = RemoteSensing_public,
                          active = RemoteSensing_active,
                          private = RemoteSensing_private,
                          lock_class = TRUE,
                          lock_objects = TRUE,
                          portable = FALSE,
                          class = TRUE,
                          cloneable = FALSE
)
