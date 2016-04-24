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
Sub LogStartupMessage(message As String)
	LogMessage(message, "startup")
End Sub

Sub LogShowStartMessage(message As String,  instareq=invalid)
	LogMessage(message, "slideshow", instareq)
End Sub

Sub LogRegistryMessage(message As String,  instareq=invalid)
	LogMessage(message, "registry", instareq)
End Sub


Sub LogSlideViewMessage(message As String,  instareq=invalid)
	LogMessage(message, "slideview", instareq)
End Sub

Sub LogVideoMessage(message As String,  instareq=invalid)
	LogMessage(message, "video", instareq)
End Sub


Sub LogSpringBoardMessage(message As String,  instareq=invalid)
	LogMessage(message, "springboard", instareq)
End Sub

Sub LogAboutMessage(message As String,  instareq=invalid)
	LogMessage(message, "about", instareq)
End Sub

Sub LogRegScreenMessage(message As String)
	LogMessage(message, "regscreen")
End Sub

Sub LogRadioMessage(message As String,  instareq=invalid)
	LogMessage(message, "radio", instareq)
End Sub

Sub LogFeedfmStartMessage(message As String,  instareq=invalid)
	LogMessage(message, "ffmstart", instareq)
End Sub


Sub LogScreenSaverMessage(message As String,  instareq=invalid)
	LogMessage(message, "screensaver", instareq)
End Sub

Sub LogStoreMessage(message As String,  instareq=invalid)
	LogMessage(message, "store", instareq)
End Sub

Sub LogDebugMessage(message As String,  instareq=invalid)
	LogMessage(message, "debug", instareq)
End Sub

Sub LogErrorMessage(message As String,  instareq=invalid)
	LogMessage(message, "error", instareq)
End Sub

Sub LogSearchMessage(message As String,  instareq=invalid)
	LogMessage(message, "search", instareq)
End Sub


Sub LogMessage(message As String, logtype=invaid, instareq=invalid)
	if message <> invalid
		print message
	end if
End Sub

Sub LogExitingMessage(message As String)
	if message <> invalid
		print message
	end if
End Sub

