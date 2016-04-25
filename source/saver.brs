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

Function HackStripHttps(url as String) As String
	
	ret = url

	globals = GetGlobals()
	
	if globals.sslPatchDomain <> invalid AND Len(globals.sslPatchDomain) > 0
		index = Instr(1, url, globals.sslPatchDomain)
		if (index > 0) 
			ret = "http://" + Mid(url, index, Len(url) - index + 1)
		end if
	end if
	
	return ret
End Function

Function CreateScreenSaver() As Object
	this = {
		port: invalid,
		canvas: invalid,
		instareq: invalid,
		
		thumbs: CreateObject("roArray", 20, false),
		currentData: CreateObject("roArray", 20, false),
		nextData: CreateObject("roArray", 20, false),
		
		itemHash: CreateObject("roAssociativeArray"),
		
		next_url: invalid,
		max_timestamp: invalid,
		saverType: "Beautiful",
		description: "Beauty on Instagram",
		
		btnChangeFeed: 0,
		btnChangeBanner: 1,
		btnPreview: 2,
		btnClose: 3,
		
		banner: "www.mylyve.com",
		
		InitLayout: ScreenSaverInitLayout,
		GetData: ScreenSaverGetData,
		FetchData: ScreenSaverFetchData,
		WaitForHttp: ScreenSaverWaitForHttp,
		
		Run: ScreenSaverRun,
		RunSettings: ScreenSaverRunSettings,
		ReadRegistry: ScreenSaverReadRegistry,
		ShowKeyboardScreen: ScreenSaverShowKeyboardScreen
	}

	this.InitLayout()
	
	return this
	
End Function


Sub ScreenSaverRun()

	LogStartupMessage("ScreenSaver")
	
	globals = GetGlobals()

	m.port = CreateObject("roMessagePort")
	m.canvas = CreateObject("roImageCanvas")

	m.canvas.SetMessagePort(m.port)
	m.canvas.SetRequireAllImagesToDraw(true)
	m.canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
	
	m.access_token = RegRead("access_token")

	if m.access_token = invalid
		m.canvas.SetLayer(1, {Text:"Link to Google using: Settings > Screensaver > QuickPony > Custom settings"})
	else
		m.canvas.SetLayer(1, {Text:"Loading."})
	end if
	m.canvas.Show()
	
	reqUrl = invalid
	count = 0
	
	crect = m.canvas.GetCanvasRect()
	mostRecentUrl = invalid
	
	xfer = CreatePwaRequest()
	resp = xfer.GetToXml()

		if resp.code <> 200
			m.canvas.SetLayer(1, {Text:resp.failure})
			m.canvas.Show()
			while true
			end while
		else
			feed = resp.root
			
			instantUploadAlbumId = invalid
			
			m.canvas.SetLayer(1, {Text:"Searching for InstantUpload album ..."})
			for each entry in feed.entry
				albumType = entry.GetNamedElements("gphoto:albumType").getText()
				print "albumType: " + albumType
				if albumType = "InstantUpload"
					instantUploadAlbumId = entry.GetNamedElements("gphoto:id").getText()
					exit for
				end if
			next
			
			if instantUploadAlbumId <> invalid
				print "instantUploadAlbumId:" + tostr(instantUploadAlbumId)
				xfer = CreatePwaRequest()
				xfer.endpoint = "/albumid/" + instantUploadAlbumId
				resp = xfer.GetToXml()
				feed = resp.root
			else
				m.canvas.SetLayer(1, {Text:"Failed to find InstantUpload album ..."})
			end if
			
			
			index = 0
			
			print "here we go " + tostr(feed.entry.Count()) + " photos in this feed"
		
			while true

				entry = feed.entry[index]
				mg = entry.GetNamedElements("media:group")
				mc = mg.GetNamedElements("media:content")
				print mc@url
				mostRecentUrl = mc@url
	
				if mostRecentUrl <> invalid
	
					print "SHOW: " + mostRecentUrl
					
					m.canvas.ClearLayer(1)
					m.canvas.SetLayer(2, {Url:mostRecentUrl})
					counterText = tostr(index) + " of " + tostr(feed.entry.Count())
					tattrs = {Font:"Small", HAlign:"Right", VAlign:"Top"}
					m.canvas.SetLayer(3, {Text:counterText, TextAttrs:tattrs})
					m.canvas.Show()
					
				msg = wait(1000, m.port)
				
				end if
						
				index = index + 1
				if index >= feed.entry.Count() 
					index = 0
				end if
				m.canvas.PurgeCachedImages()
	
			end while
		end if
		
End Sub

Sub ScreenSaverInitLayout()
					
	thumbx = 124
	thumby = 124
	fatmargin = 20
	
	xoffs = CreateObject("roArray", 4, false)
	xoffs.Push(320 - 5 - thumbx - 5 - thumbx - fatmargin)
	xoffs.Push(320 - 5 - thumbx - fatmargin)
	xoffs.Push(320 + 640 + 5 + fatmargin)
	xoffs.Push(320 + 640 + 5 + thumbx + 5 + fatmargin)
	
	yoffs = CreateObject("roArray", 5, false)
	yoffs.Push(40)
	yoffs.Push(40 + thumby + 5)
	yoffs.Push(40 + thumby + 5 + thumby + 5)
	yoffs.Push(40 + thumby + 5 + thumby + 5 + thumby + 5)
	yoffs.Push(40 + thumby + 5 + thumby + 5 + thumby + 5 + thumby + 5)
	
	for r = 0 to yoffs.Count() - 1
		for c = 0 to xoffs.Count() - 1
			m.thumbs.Push({x:xoffs[c], y:yoffs[r] ,w:thumbx,h:thumby})
		next
	next

End Sub

Function ScreenSaverGetData() As Object

	m.currentData.Clear()
	m.itemHash.Clear()
	
	m.fetchDepth = 0
	print "=========== CALLING FETCH DATA ==================="
	m.FetchData()
	
	return m.currentData
	
End Function
	
Sub ScreenSaverFetchData() As Object

	globals = GetGlobals()
	
	print "FetchData depth:" + tostr(m.fetchDepth)
	m.fetchDepth = m.fetchDepth + 1
	
	if m.nextData.Count() > 0
		print tostr(m.nextData.Count()) + " items left over"
		for each item in m.nextData
			m.currentData.Push(item)
			m.itemHash[item.id] = item.id
		next
	end if
	
	m.nextData.Clear()
	
	ret = invalid
	
	ireq = CreateInstaRequest(m.port)
	
	if m.next_url <> invalid
		ireq.url = m.next_url
	else
		ireq.endpoint = "/users/688735824/media/recent"
		'ireq.access_token = globals.feeds.beauty.access_token
	end if
	
	ireq.StartGetToString()
	json = m.WaitForHttp()
	
	m.next_url = invalid
	
	if json <> invalid
		parsedResponse = ParseJson(json)
		if parsedResponse <> invalid
			if parsedResponse.meta.code = 200
				
				print tostr(parsedResponse.data.Count()) + " items returned"
				m.canvas.SetLayer(1, {Text:"Loading.."})
				
				for each item in parsedResponse.data
					
					m.max_timestamp = item.created_time
					
					if m.currentData.Count() < 20
						if NOT m.itemHash.DoesExist(item.id)
							m.itemHash[item.id] = item.id
							print tostr(m.currentData.Count()) + " :: " + item.id + ":: adding current item posted by " + item.user.username + " at " + item.created_time
							m.currentData.Push(item)
						else 
							print "Skipping item " + item.id
						end if
					else if m.nextData.Count() < 20
						if NOT m.itemHash.DoesExist(item.id)
							m.itemHash[item.id] = item.id
							print tostr(m.nextData.Count()) + " :: " + item.id + ":: adding next item posted by " + item.user.username + " at " + item.created_time
							m.nextData.Push(item)
						else 
							print "Skipping (next) item " + item.id
						end if
						
					else
						print "ERROR too much data!!"
						exit for
					end if
				next
				
				if m.base_url = invalid
					m.base_url = ireq.url
				end if
				
				if parsedResponse.pagination <> invalid AND parsedResponse.pagination.next_url <> invalid
					m.next_url = parsedResponse.pagination.next_url
				else
					if Instr(1, ireq.url, "/media/search") > 0 AND m.max_timestamp <> invalid
						print "this is a search url, use max date??"
						m.next_url = m.base_url + "&max_timestamp=" + m.max_timestamp.Trim()
					else
						m.next_url = m.base_url
					end if
				end if
				print "next_url:" + m.next_url
				
				if m.currentData.Count() < 20 AND m.fetchDepth < 3
					print "Calling fetch data recursively m.currentData.Count() = " + tostr(m.currentData.Count())
					m.FetchData()
				else
					print "Done fetching data current / next = " + tostr(m.currentData.Count()) + " / " + tostr(m.nextData.Count())
				end if
				
			else
				print "Bad return code: " + json
			end if
		else
			print "invalid parsed Response"
			print json
		end if
	else
		print "invalid json"
	end if
	
End Sub			
					
Sub ScreenSaverRunSettings()
		
	LogStartupMessage("ScreenSaverSettings")
	
	access_token = RegRead("access_token")
    if access_token <> invalid
    	print "We already gots a token bro: " + access_token
    else
    	GetDeviceLinkingCode()
    end if

		
End Sub

Sub GetDeviceLinkingCode()
	globals = GetGlobals()
	
	PICASAWEB_GOOGLE_DATA_SCOPE = "https://picasaweb.google.com/data/"
	   
	xfer = CreateObject("roUrlTransfer")
	port = CreateObject("roMessagePort")
	xfer.SetPort(port)
	xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
	xfer.SetUrl("https://accounts.google.com/o/oauth2/device/code")
	body = "client_id="
	body = body + xfer.UrlEncode(globals.google.CLIENT_ID)
	body = body + "&scope=" + xfer.UrlEncode(PICASAWEB_GOOGLE_DATA_SCOPE)
	print body
	xfer.AsyncPostFromString(body)
	
	while true
		msg = wait(0, port)
		
		if msg <> invalid then
			if type(msg)="roUrlEvent" then
				identity  = msg.GetSourceIdentity()
				json = msg.GetString()
				print "PWS(" + tostr(identity) + "):" + "::response: code=" + Stri(msg.GetResponseCode())
				if json <> invalid
					print chr(10) + json + chr(10)
					
					ShowMessageDialog(ParseJson(json))
					exit while
				else
					print "<empty body>"
				end if
			end if
		end if
	end while
	
End Sub    

Function ShowMessageDialog(googleDeviceReg) As Void
	port = CreateObject("roMessagePort")
	screen = CreateObject("roCodeRegistrationScreen")
	screen.SetMessagePort(port)
	screen.SetTitle("[Registration screen title]")
	screen.AddParagraph("[Registration screen paragraphs are justified to right and left edges]")
	screen.AddFocalText(" ", "spacing-dense")
	screen.AddFocalText("From your computer,", "spacing-dense")
	screen.AddFocalText("go to " + googleDeviceReg.verification_url, "spacing-dense")
	screen.AddFocalText("and enter this code:", "spacing-dense")
	screen.AddFocalText(" ", "spacing-dense")
	screen.SetRegistrationCode(googleDeviceReg.user_code)
	screen.AddParagraph("[Registration screen paragraphs are justified to right and left edges and may continue on multiple lines]")
	'screen.AddButton(0, "get a new code")
	'screen.AddButton(1, "back")
	screen.Show()
	while true
    	dlgMsg = wait(googleDeviceReg.interval * 1000, port)
    	ret = PollGoogle(googleDeviceReg)
    	if ret = 200 then 
    		exit while
    	end if
    end while
    	
    access_token = RegRead("access_token")
    if access_token <> invalid
    	print "Contgrats bro: " + access_token
    end if
End Function

Function PollGoogle(googleDeviceReg)
		
	print "Polling Google .. "
	globals = GetGlobals()
		
	xfer = CreateObject("roUrlTransfer")
	port = CreateObject("roMessagePort")
	xfer.SetPort(port)
	xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
	xfer.SetUrl("https://www.googleapis.com/oauth2/v4/token")
	body = "client_id="
	body = body + xfer.UrlEncode(globals.google.CLIENT_ID)
	body = body + "&client_secret=" + xfer.UrlEncode(globals.google.CLIENT_SECRET)
	body = body + "&code=" + xfer.UrlEncode(googleDeviceReg.device_code)
	body = body + "&grant_type=" + xfer.UrlEncode("http://oauth.net/grant_type/device/1.0")
	
	print body
	
	curl = "curl -d "+chr(34)+"client_id="
		curl = curl + globals.google.CLIENT_ID
		curl = curl + "&client_secret=" + globals.google.CLIENT_SECRET
		curl = curl + "&code=" + googleDeviceReg.device_code
		curl = curl + "&grant_type=" + "http://oauth.net/grant_type/device/1.0" + chr(34) + " https://www.googleapis.com/oauth2/v4/token"
	print curl
	
	xfer.AsyncPostFromString(body)
		
		while true
			msg = wait(0, port)
			
			if msg <> invalid then
				if type(msg)="roUrlEvent" then
					identity  = msg.GetSourceIdentity()
					json = msg.GetString()
					print "PWS(" + tostr(identity) + "):" + "::response: code=" + Stri(msg.GetResponseCode())
					if msg.GetResponseCode() <> 200
						print "FailureReason:" + msg.GetFailureReason()
					else
						print "writing to registry"
						response = ParseJson(json)
						RegWrite("access_token", response.access_token)
						RegWrite("refresh_token", response.refresh_token)
					end if
					if json <> invalid
						print chr(10) + json + chr(10)
						
					else
						print "<empty body>"
					end if
					return msg.GetResponseCode()
				end if
			end if
		end while
		
		
End Function


Sub ScreenSaverShowKeyboardScreen()  

	screen = CreateObject("roKeyboardScreen")
	port = CreateObject("roMessagePort") 
	screen.SetMessagePort(port)
	screen.SetMaxLength(40)
	if m.banner <> invalid
		screen.SetText(m.banner)
	end if
	screen.SetDisplayText("enter text for banner")
	screen.AddButton(1, "Done")
	screen.AddButton(2, "Clear")
	screen.AddButton(3, "Back")
	screen.Show() 
	
	while true
	    msg = wait(0, screen.GetMessagePort()) 
	    print "message received"
	    if type(msg) = "roKeyboardScreenEvent"
	        if msg.isScreenClosed()
	            exit while
	        else if msg.isButtonPressed() then
	            print "Evt:"; msg.GetMessage ();" idx:"; msg.GetIndex()
	            if msg.GetIndex() = 1
	                text = screen.GetText()
	                print "search text: "; text 
	                if text = ""
	                	print "text empty, returning invalid"
	                	text = invalid
	                end if
		        	WriteScreenSaver("banner", text)
	                exit while
	            else if msg.GetIndex() = 2
	            	screen.SetText("")
		        	WriteScreenSaver("banner", invalid)
	            else
	            	exit while
	            end if
	        endif
	    endif
	 end while
	
End Sub

Sub ScreenSaverReadRegistry()

End Sub
					

Function ScreenSaverWaitForHttp()

	ret = invalid
	
	msg = wait(0, m.port)
	
	if type(msg)="roUrlEvent" then
		gi = msg.GetInt()
		if gi = 1 then
			ret = msg.GetString()
		else
			print "ERROR gi:" + Stri(gi)
		end if
	end if
	
	return ret

End Function 
