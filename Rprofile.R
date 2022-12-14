# install only precompiled binaries
options(install.packages.check.source = "never")
options(pkgType = "win.binary")

if (!identical(system.file(package="RevoUtils"), "")) {
	Revo.version <- RevoUtils:::makeRevoVersion()
	# repos.date <- utils::packageDescription("RevoUtils")$MRANDate
	repos.date <- "2022-09-01"		# manually overriding
}

if (!identical(system.file(package="RevoScaleR"), "")) {
    if (.Platform$OS.type == "windows"){
        defaultRevoNodePath <- paste("C:\\Program Files\\Microsoft\\MRO-for-RRE\\", paste(Revo.version$major, substr(Revo.version$minor,1,1), sep="."), sep="")
        defaultRNodePath <- utils::shortPathName(R.home())
    } else {
        defaultRevoNodePath <- paste("/usr/lib64/MRS-", paste(Revo.version$major, substr(Revo.version$minor,1,1), sep="."), sep="")
        defaultRNodePath <- paste(defaultRevoNodePath, "/R-", paste(R.version$major, R.version$minor, sep="."), "/lib64/R", sep="")
    }
}

local(
{
	# set a CRAN mirror
	# r <- getOption("repos")
	if (.Platform$OS.type == "unix") {
		options(download.file.method = "curl")
	}
	# r["CRAN"] <- RevoUtils::getRevoRepos()
	# options(repos=r)
	options(repos = "https://mran.microsoft.com/snapshot/2022-09-01")		# manually overriding

    MRS.is.client <- RevoUtils:::isMicrosoftRClient()
    # set default packages
	# For MicrosoftML, check to see if this is a supported platform (Windows, RHEL/Cent 7, Ubuntu 14.04/16.04)
	isMMLSupported <- FALSE
	if (identical(.Platform$OS.type,"windows")) {
		isMMLSupported <- TRUE
	}
	
	# commenting out configs for other platforms 
	# if (identical(.Platform$OS.type, "unix") && length(grep("Ubuntu",Sys.info()["version"]))){
	#	if (file.exists("/etc/lsb-release")){
	#		UbuntuReleaseInfo <- scan("/etc/lsb-release", what="", sep="\n", quiet=TRUE)
	#		if (identical(UbuntuReleaseInfo[2], "DISTRIB_RELEASE=14.04") || identical(UbuntuReleaseInfo[2], "DISTRIB_RELEASE=16.04")) {
	#			isMMLSupported <- TRUE
	#		}
	#	}
	# }
	# if ( identical(.Platform$OS.type, "unix") && length(grep("el7.x86_64",Sys.info()["release"]))){
	#	isMMLSupported <- TRUE
	# }
	
	if (!identical(system.file(package="RevoScaleR") , "")){
	# customizing packages to load at startup by default
        options(defaultPackages = c(getOption("defaultPackages"), "rpart", "lattice", "RevoScaleR"))
		# checks for SQL Server R deployment environment
            # if(!identical(system.file(package="mrsdeploy"), "") && identical(.Platform$OS, "windows") && !identical(Sys.getenv("MRS_IN_DATABASE_HOST_PLATFORM"), "1")) "mrsdeploy",
			# we have MicrosoftML package"""
			
			# machine learning configs using clusters & Apache hadoop!
			# if(!identical(system.file(package="MicrosoftML"),"") && isMMLSupported) "MicrosoftML", 
			# "RevoMods", "RevoUtils", "RevoUtilsMath"), mleap.home = Sys.getenv("MLEAP_HOME"))
        # if (nchar(hostName <- Sys.getenv("REVOHADOOPHOST")) && nchar(portNumber <- Sys.getenv("REVOHADOOPPORT")))
		# {
		#	 RevoScaleR::rxHdfsConnect(hostName=hostName, portNumber=as.numeric(portNumber))
		# }
	} else {
		options(defaultPackages=c(getOption("defaultPackages"), "RevoUtils"))
	}
	
	# branding information
	.RevoVersionShort <- Revo.version$version.string
	.RevoVersionShortLen <- regexpr("^.* \\d+\\.\\d+", .RevoVersionShort,  perl=TRUE)
	.RevoVersionShort <- substring(.RevoVersionShort, 1, attributes(.RevoVersionShortLen)$match)
	if ("setWindowTitle" %in% getNamespaceExports("utils")) {
		if (Revo.version$arch=="x86_64") {
	        .RevoVersionShort <- paste0(.RevoVersionShort, " (64-bit)")
		}
		try(utils::setWindowTitle(paste(" - ", .RevoVersionShort)), silent=TRUE)
	}
	
	# UNIX platform configs
	# if (.Platform$OS.type == "unix" && capabilities("X11")) {
	#	browseAvail <- Sys.which(c("firefox", "mozilla", "galeon", "opera", "xdg-open", "kfmclient", "gnome-moze-remote"))
	#	if (any(browseAvail != "")) {
	#		options(browser = browseAvail[which(browseAvail != "")[1]])
	#	}
	# }
	
    if (.Platform$OS.type == "windows" ) { 
       options(help_type="html") 
    } 

    load_if_installed <- function(package) { 
       if (!identical(system.file(package="RevoUtilsMath"), "")) { 
       do.call('library', list(package)) 
       return(TRUE) 
       } else { 
          return(FALSE) 
	   }  
    } 

	if (identical(system.file(package="RevoScaleR"), "")) {
		if (load_if_installed("RevoUtilsMath")) {
			ncores <- RevoUtilsMath::getMKLthreads()
		} else {
			MROversion <- paste(Revo.version$major, Revo.version$minor, sep=".")
			MKLmsg <- "No performance acceleration libraries were detected. To take advantage of \nthe available processing power, also install MKL for R Open. Visit \nhttp://go.microsoft.com/fwlink/?LinkID=698301 for more details.\n"
		}

		# for Apple systems
		#	if (Sys.info()["sysname"] == "Darwin") {
		#	options(download.file.method = "libcurl") 
		#	hw.ncpu <- try(system('sysctl hw.physicalcpu', intern = TRUE)) 
		#	if (!inherits(hw.ncpu, "try-error")) { 
		#		ncores <- sub("hw.physicalcpu: ", "", hw.ncpu) 
		#		MKLmsg = paste0("Multithreaded BLAS/LAPACK libraries detected. Using ", ncores, " cores for math algorithms.\n")
		#	}
		# } else {
			if (load_if_installed("RevoUtilsMath")) {
				ncores <- RevoUtilsMath::getMKLthreads()
				MKLmsg = ""
			} else {
				MROversion <- paste(Revo.version$major, Revo.version$minor, sep=".")
				MKLmsg <- "No performance acceleration libraries were detected. To take advantage of \nthe available processing power, also install MKL for R Open. \n\nVisit http://go.microsoft.com/fwlink/?LinkID=698301 for more details."
			}      
		# }
	} else {
		ncores <- RevoUtilsMath::getMKLthreads()
		MKLmsg <- ""
	}
	
	# configs for invocation of R from command line
	quiet <- any(match(c("-q", "--silent", "--quiet", "--slave"), commandArgs()), na.rm=TRUE)
	# if (!quiet && !identical(system.file(package="RevoScaleR") , "")) {
    #    cat("Microsoft R Open ",R.version$major,".",R.version$minor,"\n",sep="")
    #    cat("The enhanced R distribution from Microsoft\n",sep="")
    #    cat("Microsoft packages Copyright (C)", Revo.version$year, "Microsoft\n\n")
        # if (MRS.is.client == FALSE) {
		#   ScaleRPkgName <- "RevoScaleR"
		#   pkgVersion <- utils::packageDescription(ScaleRPkgName)$Version
		#   cat("Loading Microsoft Machine Learning Server packages, version ", pkgVersion,".\n", sep = "")
		# } else {
		#   RclientPkgName <- "MicrosoftR"
		#   pkgVersion <- utils::packageDescription(RclientPkgName)$Version
		#   cat("Loading Microsoft R Client packages, version ", pkgVersion,". \n", sep = "")
		#   cat("Microsoft R Client limits some functions to available memory.\n") 
		#   cat("See: https://go.microsoft.com/fwlink/?linkid=799476 for information\n",sep="")
		#   cat("about additional features.\n\n",sep="")
		# }   
		# cat("Type 'readme()' for release notes, privacy() for privacy policy, or\n", sep = "")
		# cat("'RevoLicense()' for licensing information.\n\n", sep = "")
        # if (MKLmsg == "") {
		#   cat(paste("Using the Intel MKL for parallel mathematical computing (using", ncores, "cores).\n", sep = " "))
		# } else {
		#   cat(MKLmsg, MROversion, sep = " ")
		# }
		# cat(paste("Default CRAN mirror snapshot taken on ",repos.date, ".\n",sep=""))
		# cat("See: https://mran.microsoft.com/.", "\n\n", sep = "")
	# } else 
	if (!quiet) {
		cat("Microsoft R Open ",R.version$major,".",R.version$minor,"\n",sep="")
        cat("The enhanced R distribution from Microsoft\n",sep="")
        cat("Microsoft packages Copyright (C)", Revo.version$year, "Microsoft Corporation\n\n")
		if (MKLmsg == "") {
		   cat(paste("Using the Intel MKL for parallel mathematical computing (using", ncores, "cores).\n", sep = " "))
		} else {
		   cat(MKLmsg)
		}
		cat("\nDefault CRAN mirror snapshot taken on ",repos.date, ".", sep = "")
		# cat("\n", "See: https://mran.microsoft.com/.",sep="")
		cat("\n")
	}	
}) 



