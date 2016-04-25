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

Function CreatePwaRequest() As Object
	this = {
		
		url: invalid,
		
		apiBase: "https://picasaweb.google.com/data/feed/api/user/default",
		endpoint: "",
		access_token:  RegRead("access_token"),
		qparams: invalid,
		bparams: invalid,
		body: invalid,
		
		' Google Data Protocol generic flags
		pretty: true,
		max_results: 100,
		
		type: "pwa",
		
		port: CreateObject("roMessagePort"),
		xfer: CreateObject("roUrlTransfer"),
		
		identity: invalid,
		
		AddBodyParam: PwaRequestAddBodyParam,
		AddQueryParam: PwaRequestAddQueryParam,
		
		ClearParams: PwaRequestClearParams,
		Build: PwaRequestBuild,
		
		StartGetToString: PwaRequestStartGetToString,
		GetToString: PwaRequestGetToString,
		
		GetToXml: PwaRequestGetToXml,
		
		PostFromString: PwaRequestPostFromString,
		DeleteFromString: PwaRequestDeleteFromString,
		
		PostWithStatus: PwaRequestPostWithStatus,
		DeleteWithStatus: PwaRequestDeleteWithStatus,
		
		ParseResponse: PwaRequestParseResponse,
		
		RefreshToken: PwaRequestRefreshToken,
		refreshed: false,
		
		Close: function() : m.xfer.AsyncCancel() : m.xfer = invalid : return m.xfer : end function
	}

	' allow for HTTPS
	this.xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
	this.xfer.InitClientCertificates()
	this.xfer.SetPort(this.port)
	this.xfer.EnableEncodings(true)
	this.xfer.AddHeader("GData-Version", "2")

	
	this.identity = this.xfer.GetIdentity()
	
	return this
End Function

' Since many old browsers don't support PUT or DELETE, we've made it 
'easy to fake PUTs and DELETEs. All you have to do is do a POST with 
'_method=PUT or _method=DELETE as a parameter and we will treat it as 
'if you used PUT or DELETE respectively.

Sub PwaRequestClearParams()
	if m.qparams <> invalid then
		m.qparams = invalid
	end if
End Sub


Sub PwaRequestAddQueryParam(name,value)
	'print "add query " + name + " = " + tostr(value)
	if m.qparams = invalid then
		m.qparams = {}
	end if

	m.qparams[name] = value
	
End Sub

Sub PwaRequestAddBodyParam(name,value)
	print "add body " + name + " = " + tostr(value)
	if m.bparams = invalid then
		m.bparams = []
	end if
	param = {}
	param.name = name
	param.value = value
	m.bparams.Push(param)
End Sub

Sub PwaRequestBuild()
	debug = m.url
	
	if m.pretty <> invalid
		m.AddQueryParam("pretty", m.pretty)
	end if
	
	if m.max_results <> invalid
		m.AddQueryParam("max-results", m.max_results)
	end if
	
	if m.url = invalid then
		debug = m.endpoint
		m.url = m.apiBase + m.endpoint
		if (m.access_token <> invalid) then
			if m.bparams = invalid 
				m.url = m.url + "?access_token=" + m.xfer.UrlEncode(m.access_token)
				debug = debug  + "?access_token=<token>"
			else
				m.AddBodyParam("access_token", m.access_token)
			end if
		end if
		
		if m.qparams <> invalid then
			m.qparams.Reset()
			while m.qparams.IsNext()
				key = m.qparams.Next()
				val = tostr(m.qparams[key])
			
				encoded = "&" +  m.xfer.UrlEncode(key) + "=" + m.xfer.UrlEncode(val)
				m.url = m.url + encoded
				debug = debug + encoded
				
			end while
		end if
		
		if m.bparams <> invalid then

			for each param in m.bparams
				val = tostr(param.value)
				if m.body = invalid then
					m.body =  m.xfer.UrlEncode(param.name) + "=" + m.xfer.UrlEncode(val)
				else
					m.body = m.body + "&" + m.xfer.UrlEncode(param.name) + "=" + m.xfer.UrlEncode(val)
				end if
			next
		end if
		
	end if
    print "request(" +Stri(m.identity)+ "): " + m.url 
    m.debug = debug
    m.xfer.SetUrl(m.url)
End Sub

Sub PwaRequestStartGetToString()
	m.Build()	
	m.xfer.AsyncGetToString()
End Sub

Sub PwaRequestRefreshToken()
		
	refresh_token = RegRead("refresh_token")	
	print "refreshing access_token using: " + refresh_token
	
	globals = GetGlobals()
	
	xfer = CreateObject("roUrlTransfer")
	port = CreateObject("roMessagePort")
	
	xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
	xfer.SetPort(port)
	
	body = "client_id=" + xfer.UrlEncode(globals.google.CLIENT_ID)
	body = body + "&client_secret=" + xfer.UrlEncode(globals.google.CLIENT_SECRET)
	body = body + "&refresh_token=" + xfer.UrlEncode(refresh_token)
	body = body + "&grant_type=refresh_token"
	
	xfer.SetUrl("https://www.googleapis.com/oauth2/v4/token")
	
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
				else
					print "<empty body>"
				end if
				if msg.GetResponseCode() <> 200
					print "FailureReason:" + msg.GetFailureReason()
				else
					print "writing to registry"
					response = ParseJson(json)
					m.access_token = response.access_token
					RegWrite("access_token", response.access_token)
					if response.refresh_token <> invalid
						RegWrite("refresh_token", response.refresh_token)
					end if
					exit while
				end if
			end if
		end if
	end while

	m.refreshed = true
End Sub
'RegWrite("access_token", "ya29..zwKvMpm_guu7kBOZm0fqc9L38kNu2qLMQKUtQxXp0yWSZTN-YUU0y_HGMyLMg6F5_Q")
Function PwaRequestGetToXml()
	
	ret = {}
	
	print "PwaRequestGetToXml m.refreshed=" + tostr(m.refreshed) + ", access_token:" + m.access_token
	m.Build()	
	m.xfer.AsyncGetToString()
	
	msg = wait(0, m.port)
	feed = invalid
	
	if msg <> invalid then
		if type(msg)="roUrlEvent" then
			identity  = msg.GetSourceIdentity()
			xml = msg.GetString()
			ret.body = xml
			ret.code =  msg.GetResponseCode()
			ret.failure = msg.GetFailureReason() 
			
			print "PWS(" + tostr(identity) + "):" + "::response: code=" + Stri(ret.code)
			
			if ret.code = 403 AND NOT m.refreshed
				m.RefreshToken()
				return m.GetToXml()
			else if ret.code = 200
			
				if xml <> invalid
					print chr(10) + xml + chr(10)
					root = CreateObject("roXMLElement")
					root.Parse(xml)
					
					ret.root = root
				else
						print "<empty body>"
				end if
			end if
		end if ' urlevent
	end if ' msg invalid
	
	
	return ret
	
End Function

Function PwaRequestGetToString() As String
	m.Build()	
	return m.xfer.GetToString()
End Function


Function PwaRequestPostFromString(request="") 
	m.Build()	
	return m.xfer.PostFromString(request)
End Function


Function PwaRequestDeleteFromString(request="") 
	m.xfer.SetRequest("DELETE")
	m.Build()	
	return m.xfer.PostFromString(request)
End Function

Function PwaRequestDeleteWithStatus(title="Please wait ..")
	m.xfer.SetRequest("DELETE")
	return m.PostWithStatus(title)
End Function

Function PwaRequestPostWithStatus(title="Please wait ..")
	ret = invalid
	m.Build()
	port = CreateObject("roMessagePort")
	busyDialog = CreateObject("roOneLineDialog")
	m.xfer.SetPort(port)
	busyDialog.SetMessagePort(port)
	 
	busyDialog.SetTitle(title)
	busyDialog.ShowBusyAnimation()
	busyDialog.Show()
	body = ""
	if m.body <> invalid then
		body = m.body
		print "body:" + body
	end if

	m.xfer.AsyncPostFromString(body)
	
	while true
		msg = WaitForEvent(0, port)
		
		if msg <> invalid then
			if type(msg)="roUrlEvent" then
				identity  = msg.GetSourceIdentity()
				json = msg.GetString()
				print "PWS(" + tostr(identity) + "):" + "::response: code=" + Stri(msg.GetResponseCode())
				if json <> invalid
					print chr(10) + json + chr(10)
				else
					print "<empty body>"
				end if

				if msg.GetSourceIdentity() = m.identity
					busyDialog.Close()
					ret = msg
					exit while
				end if
			else if type(msg) = "roOneLineDialogEvent"
				if msg.isScreenClosed() then
					exit while
				end if
			end if
		end if
	end while
		
	return ret
	
End Function

Function PwaRequestParseResponse(json)
		
	ret = invalid
	if json <> invalid
		parsedResponse = ParseJson(json)
		if parsedResponse <> invalid
			if parsedResponse.meta.code = 200
				return parsedResponse
			else
				return "Unexpected result"
			end if
		else
			return "Unexpected result"
		end if
	else
		return "Unexpected result"
	end if
	
	return ret
		
End Function		