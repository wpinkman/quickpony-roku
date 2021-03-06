Sub Main()

	print "Run QuickPony, run ... "
	
	facade = CreateFacade()
	facade.Show()
	
	'RunScreenSaverSettings()
	RunScreenSaver()
	
	
End Sub



Function CreateFacade()

	canvas = CreateObject("roImageCanvas")
	port = CreateObject("roMessagePort")
	canvas.SetMessagePort(port)
	'Set opaque background
	canvas.SetLayer(0, {Color:"#FF000000", Text: "Giddy Up!", CompositionMode:"Source"})
	
	return canvas
End Function


Sub PlayVideo(episode)

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen") 
   

    screen.SetContent(episode)
    screen.SetMessagePort(port)
    screen.Show() 

    while true
       msg = wait(0, port)
    
       if type(msg) = "roVideoScreenEvent" then
           print "showVideoScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
           if msg.isScreenClosed()
               print "Screen closed"
               exit while
            else if msg.isStatusMessage()
                  print "status message: "; msg.GetMessage()
            else if msg.isPlaybackPosition()
                  print "playback position: "; msg.GetIndex()
            else if msg.isFullResult()
                  print "playback completed"
                  exit while
            else if msg.isPartialResult()
                  print "playback interrupted"
                  exit while
            else if msg.isRequestFailed()
                  print "request failed – error: "; msg.GetIndex();" – "; msg.GetMessage()
                  exit while
            end if
       end if
    end while 

End Sub

Function codeToIP(num) 
    return 0'[(num >>> 24) & 0xff, (num >>> 16) & 0xff, (num >>> 8) & 0xff, num & 0xff].join('.');
End Function


Sub RunScreenSaverSettings()
	SetTheme()
	saver = CreateSgScreenSaver()
	saver.RunSettings()

End Sub

Sub RunScreenSaver()
	GetGlobals().saver = true
	saver = CreateSgScreenSaver()
	saver.Run()
End Sub

Sub FetchLyveData()
	'http://192.168.1.86:8080/bps/queries?type=getdistinctdates

	port = CreateObject("roMessagePort")
	lcReq = CreateLyveCastRequest(port)
	lcReq.endpoint = "/queries"
	lcReq.AddQueryParam("type", "getdistinctdates")
	

	json = lcReq.GetToString()
	
	'print json
	resp = ParseJson(json)
	
	print "returned " + Stri(resp.data.Count()) " ids, uuid=" + resp.uuid
	
	
	idarray = []
	for each item in resp.data
		idarray.Push(item.id)
	next
			
	
	lcReq = CreateLyveCastRequest(port)
	lcReq.endpoint = "/resolve"
	lcReq.AddQueryParam("uuid", resp.uuid)
	'print ids
	
	json = lcReq.PostIds(idarray)
	
	ssdata = []
	
	if json <> invalid
		'print json
		resp = ParseJson(json)
		
		if resp <> invalid 
		
		print  Stri(resp.data.Count()) + " dates resolved"
		total = 0
		for each item in resp.data
			dateTime = CreateObject("roDateTime")
			dateTime.FromSeconds(Int(item.ts.ToFloat() / 1000))
			dateString = dateTime.AsDateString("short-month-no-weekday")
			print dateString + " count:" + item.count
			
			lcReq = CreateLyveCastRequest(port)
			lcReq.endpoint = "/queries"
			lcReq.AddQueryParam("type", "getbydate")
			lcReq.AddQueryParam("date", item.ts)
			json = lcReq.GetToString()
			
			'print json
			gbdResp = ParseJson(json)
			print "  " + gbdResp.uuid
			idarray = []
			for each idobj in gbdResp.data
				'print "    " + Stri(total) + " " + idobj.id
				
				
				idarray.Push(idobj.id)
				'ssdata.Push({url: "http://192.168.1.86:8080/stream/thumbnails?id=" + idobj.id, TextOverlayBody:dateString})
			next
			'http://192.168.1.86:8080/stream/thumbnails?id=3a2ed60ecbb3365122b66764613f200a4a9d857d09e4b7db2366ecc89c9d5d8b'
			'total = total + item.count.ToInt()
			lcReq = CreateLyveCastRequest(port)
			lcReq.endpoint = "/resolve"
			lcReq.AddQueryParam("uuid", gbdResp.uuid)
			'print ids
			
			json = lcReq.PostIds(idarray)
			'print "resp: " + json
			gbdResp = ParseJson(json)
			for each idobj in gbdResp.data
				print "== " + Stri(total) 
				orientation = "N/A"
				if idobj.orientation <> invalid
					print "   orientation: " + idobj.orientation
					orientation = idobj.orientation
				end if
				print "   url: " + idobj.url
				print "   mime: " + idobj.mime
				print "   objID: " + idobj.objID
				print "==========================="
				total = total + 1
				ssdata.Push({url: "http://192.168.1.86:8080/stream/image?id=" + idobj.objID, TextOverlayBody:dateString, TextOverlayUR:"orientation: " + orientation})
			next
			
			if total > 99  
				exit for
			end if
		next
		print "total:" + Stri(total)
	
		else
			print "could not parse json"
		end if
	else 
		print "inavlid response"
	end if
	
	slideshow = CreateObject("roSlideShow")
	slideshow.SetMessagePort(port)
	slideshow.SetContentList(ssdata)
	slideshow.SetPeriod(6)
	slideshow.SetTextOverlayIsVisible(true)
	slideshow.SetTextOverlayHoldTime(2000)
	slideshow.SetMaxUpscale(1)
	slideshow.Show()
	
	while true
		wait(0, port)
	end while
	
End Sub

Sub SetTheme()

	globals = GetGlobals()

	if NOT globals.appInit
	    app = CreateObject("roAppManager")
	    theme = CreateObject("roAssociativeArray")
		    	
	   
	    app.SetTheme(theme)
	    
		globals.appInit = true
	else
		print "WARNING: Skipping SetTheme"
	end if
	
End Sub

