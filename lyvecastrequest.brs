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

Function CreateLyveCastRequest(port=invalid) As Object
	this = {
		
		url: invalid,
		port: port,
		
		apiBase: "http://192.168.1.86:8080/bps",
		endpoint: invalid,
		qparams: invalid,
		bparams: invalid,
		body: invalid,
				
		xfer: CreateObject("roUrlTransfer"),
		
		identity: invalid,
		
		AddBodyParam: LyveCastRequestAddBodyParam,
		AddQueryParam: LyveCastRequestAddQueryParam,
		
		ClearParams: LyveCastRequestClearParams,
		BuildUrl: LyveCastRequestBuildUrl,
		
		StartGetToString: LyveCastRequestStartGetToString,
		GetToString: LyveCastRequestGetToString,
		
		PostFromString: LyveCastRequestPostFromString,
		DeleteFromString: LyveCastRequestDeleteFromString,
		
		PostIds: LyveCastRequestPostIds,
		DeleteWithStatus: LyveCastRequestDeleteWithStatus,
		
		ParseResponse: LyveCastRequestParseResponse,
		
		Close: function() : m.xfer.AsyncCancel() : m.xfer = invalid : return m.xfer : end function
	}

	' allow for HTTPS
	'this.xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
	'this.xfer.InitClientCertificates()
	this.xfer.SetPort(port)
	'this.xfer.EnableEncodings(true)
	
	
	this.identity = this.xfer.GetIdentity()
	
	return this
End Function

' Since many old browsers don't support PUT or DELETE, we've made it 
'easy to fake PUTs and DELETEs. All you have to do is do a POST with 
'_method=PUT or _method=DELETE as a parameter and we will treat it as 
'if you used PUT or DELETE respectively.

Sub LyveCastRequestClearParams()
	if m.qparams <> invalid then
		m.qparams = invalid
	end if
End Sub


Sub LyveCastRequestAddQueryParam(name,value)
	if m.qparams = invalid then
		m.qparams = {}
	end if
	'param = {}
	'param.name = name
	'param.value = value
	m.qparams[name] = value
End Sub

Sub LyveCastRequestAddBodyParam(name,value)
	'print "add body " + name + " = " + tostr(value)
	if m.bparams = invalid then
		m.bparams = []
	end if
	param = {}
	param.name = name
	param.value = value
	m.bparams.Push(param)
End Sub

Sub LyveCastRequestBuildUrl()
	debug = m.url
	if m.url = invalid then
		debug = m.endpoint
		m.url = m.apiBase + m.endpoint
		if m.qparams <> invalid then
			m.qparams.Reset()
			sep = "?"
			while m.qparams.IsNext()
				key = m.qparams.Next()
				val = tostr(m.qparams[key])
			
				encoded = sep +  m.xfer.UrlEncode(key) + "=" + m.xfer.UrlEncode(val)
				
				sep = "&"
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

Sub LyveCastRequestStartGetToString()
	m.BuildUrl()	
	m.xfer.AsyncGetToString()
End Sub

Function LyveCastRequestGetToString() As String
	m.BuildUrl()	
	return m.xfer.GetToString()
End Function

Function LyveCastRequestPostFromString(request="") 
	m.BuildUrl()	
	return m.xfer.PostFromString(request)
End Function


Function LyveCastRequestDeleteFromString(request="") 
	m.xfer.SetRequest("DELETE")
	m.BuildUrl()	
	return m.xfer.PostFromString(request)
End Function

Function LyveCastRequestDeleteWithStatus(title="Please wait ..")
	m.xfer.SetRequest("DELETE")
	return m.PostWithStatus(title)
End Function

Function LyveCastRequestPostIds(idarray)
	ret = invalid
	
	ids = ""
		
	For i=0 To idarray.Count() - 2 
	    ids = ids + idarray[i] + ","
	End For
	ids = ids + idarray[idarray.Count() - 1]
	
	m.AddBodyParam("ids", ids)				
	
	m.BuildUrl()

	body = ""
	if m.body <> invalid then
		body = m.body
	end if

	m.xfer.AsyncPostFromString(body)
	
	while true
		print "waiting.."
		msg = wait(1000, m.port)
		
		if msg <> invalid then
			print "event:" + type(msg)
			if type(msg)="roUrlEvent" then
				identity  = msg.GetSourceIdentity()
				json = msg.GetString()
				print "PWS(" + tostr(identity) + "):" + "::response: code=" + Stri(msg.GetResponseCode())

				if msg.GetSourceIdentity() = m.identity
					ret = json
					exit while
				end if
			end if
		end if
	end while
		
	return ret
	
End Function

Function LyveCastRequestParseResponse(json)
		
	ret = invalid
	if json <> invalid
		parsedResponse = ParseJson(json)
		if parsedResponse <> invalid
			return parsedResponse
		else
			return "Unexpected result"
		end if
	else
		return "Unexpected result"
	end if
	
	return ret
		
End Function		