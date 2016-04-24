' *********************************************************
' *********************************************************
' **
' **  QuickPony Channel
' **
' **  Saul Goodman, April 2016
' **
' **  Copyright (c) 2016 Fugue State, Inc., All Rights Reserved.
' **
' *********************************************************
' *********************************************************

' *********************************************************
' *********************************************************

' Rename this file to secrets.brs and supply proper credentials

' *********************************************************
' *********************************************************



' rename function to InitSecrets()
Function InitSecretsTEMPLATE()
	ret = {}

	ret.GOOGLE_CLIENT_ID = "<insert from Google Developers Console>" 
	ret.GOOGLE_CLIENT_SECRET = "<insert from Google Developers Console>"
		
	return ret
End Function