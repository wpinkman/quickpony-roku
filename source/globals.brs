' *********************************************************
' *********************************************************
' **
' **  Rokagram Channel
' **
' **  W. Pinkman, February 2014
' **
' **  Copyright (c) 2014 Fugue State, Inc., All Rights Reserved.
' **
' *********************************************************
' *********************************************************

Function GetGlobals()
	globals = GetGlobalAA()
	if globals.init = invalid then
		InitGlobals()
	end if
	return globals
	
End Function

Sub InitGlobals()

	globals = GetGlobalAA()
	
	globals.appInit = false
	
	' ---------------- BEGIN CHECK BEFORE PACKAGING
	
	globals.localhost = true
	globals.saverTest = false
	globals.saver2Test = false
	globals.wipeonexit = false
	globals.twod = false
	
	globals.usa = true
	
	globals.trial = false
	globals.expired = false
	globals.saver = false
 
	globals.cversion = "1.0.0"
		
	globals.features = {}
	globals.features.music = globals.usa AND NOT globals.saver
	globals.features.locations = false
	globals.features.video = true
		
	' ---------------- END CHECK BEFORE PACKAGING
	if NOT globals.usa
		globals.cversion = globals.cversion + " NUS"
	end if
		
	if globals.trial
		globals.cversion = globals.cversion + " T"
	end if
	
	' prevent accidentally leaving the development server set
	devInfo = CreateObject("roDeviceInfo")
	uniqueId = devInfo.GetDeviceUniqueId()
	' safety check in case the localhost was left true
	if NOT ((uniqueId = "N0A09L015216") OR (uniqueId = "1GJ37E062368") OR (uniqueId = "12A18M065074") OR (uniqueId = "4124CG163257")) 
		globals.localhost = false
		globals.saverTest = false
		globals.saver2Test = false
		globals.twod = false
		globals.wipeonexit = false
	end if
	
		
	
	globals.port = CreateObject("roMessagePort")
	
	globals.deviceInfo = {}
	globals.deviceInfo.version = devInfo.GetVersion()
	globals.deviceInfo.displayMode = devInfo.GetDisplayMode()
		
	'example "034.08E01185A".  The third through sixth characters are the major/minor version number ("4.08")
	globals.version = Val(Mid(globals.deviceInfo.version, 3, 4))
	major = Int(Val(Mid(globals.deviceInfo.version, 3, 1)))
    minor = Int(Val(Mid(globals.deviceInfo.version, 5, 2)))
    build = Int(Val(Mid(globals.deviceInfo.version, 8, 5)))
        
    globals.version = Val(Stri(major).Trim() + "." + Stri(minor).Trim())
    
    print "Version " + tostr(globals.version) + " (build " + tostr(build) + ")"
    
	globals.constants = {}
	globals.constants.sections = {}
	globals.constants.sections.default = "default"
	globals.constants.sections.feedfm = "feedfm"
	globals.constants.sections.instagram = "instagram"
	globals.constants.sections.feedfmStations = "feedfm/stations"
	globals.constants.sections.users = "users"
	globals.constants.sections.location = "location"
	globals.constants.sections.saver = "saver"
		
	globals.constants.keys = {}
	globals.constants.keys.trial_start = "trial_start"
	globals.constants.keys.upgrade_code = "upgrade_code"
		
	globals.constants.getrokagramUid = "501866943"
		
	globals.rokagram = {}
	globals.instagram = {} 

	globals.sslPatchDomain = "scontent.cdninstagram.com"
	
	globals.rokaResponse = false

		
	
	globals.init = true
	
	' put registry based init below to avoid recusive calls
	
	globals.logging = {}
	globals.logging.reqHash = {}
	globals.logging.reqCount = 0
	
	
	globals.stats = {}
	globals.stats.clients = {}

	globals.google = {}
	globals.google.CLIENT_ID = InitSecrets().GOOGLE_CLIENT_ID
	globals.google.CLIENT_SECRET = InitSecrets().GOOGLE_CLIENT_SECRET
		
		
End Sub

Function GetGlobalPort()
	return GetGlobals().port
End Function

Function GenerateGuid() As String
' Ex. {5EF8541E-C9F7-CFCD-4BD4-036AF6C145DA}
	Return "{" + GetRandomHexString(8) + "-" + GetRandomHexString(4) + "-" + GetRandomHexString(4) + "-" + GetRandomHexString(4) + "-" + GetRandomHexString(12) + "}"
End Function

Function GetRandomHexString(length As Integer) As String
	hexChars = "0123456789ABCDEF"
	hexString = ""
	For i = 1 to length
	    hexString = hexString + hexChars.Mid(Rnd(16) - 1, 1)
	Next
	Return hexString
End Function