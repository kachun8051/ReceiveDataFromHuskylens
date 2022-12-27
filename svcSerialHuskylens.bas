B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=11.8
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
	
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
	Private AST As AsyncStreamsJson
	Private Serial3 As Serial
	Private flagIsConn As Boolean
	Private flagConnError As String
	' Which activity or page consume this service
	Private mySender As Object
	' Bluetooth mac address of HC-06 i.e. Bluetooth module
	Private myMac As String
	' current reading text from Huskylens
	Private currText As String
	' current identified id from Huskylens
	Private currId As Int
End Sub

Sub Service_Create
	flagIsConn = False
	flagConnError = ""
	mySender = Null
	' myEventHandler = ""
	myMac = ""
	currText = ""
	currId = -1
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StopAutomaticForeground 'Call this when the background task completes (if there is one)
'	If StartingIntent.HasExtra("senderid") = False Then
'		StopService("")
'		Return
'	End If
	If StartingIntent.HasExtra("sender") = False Then
		StopService("")
		Return
	End If
	If StartingIntent.HasExtra("mac") = False Then
		StopService("")
		Return
	End If
	' Dim SenderId_1 As String = StartingIntent.GetExtra("senderid")
	' mySender = B4XPages.GetPage(SenderId_1)
	mySender = StartingIntent.GetExtra("sender")
	myMac = StartingIntent.GetExtra("mac")
	Serial3.Initialize("Serial3")
	Connect3(myMac)
End Sub

Sub Service_Destroy
	DisConnect
End Sub

Public Sub getObjectId() As Int	
	Return currId
End Sub

#Region Bluetooth_fundamental
Public Sub ConnectedErrorMsg As String
	' Returns any error raised by the last attempt to connect a printer
	Return flagConnError
End Sub

Public Sub IsConnected As Boolean
	' Returns whether a printer is connected or not
	Return flagIsConn
End Sub

Public Sub IsBluetoothOn As Boolean
	' Returns whether Bluetooth is on or off
	Return Serial3.IsEnabled
End Sub

' Connect the Scale by MAC address directly
Private Sub Connect3(mac As String)
	Serial3.Connect(mac)
End Sub

Private Sub DisConnect
	' Disconnect the printer
	If Serial3.IsInitialized Then
		Serial3.Disconnect
	End If
	If AST.IsInitialized Then
		AST.Close
	End If
	flagIsConn = False
End Sub

'Public Sub FlushClose
'	If AST.IsInitialized Then
'		AST.Close
'	End If
'	Astream.SendAllAndClose
'End Sub
#End Region

#Region Internal_Serial_Events
Private Sub Serial3_Connected (Success As Boolean)
	' Internal Serial Events
	If Success Then
		If AST.IsInitialized Then AST.Close
		AST.Initialize(Me, "AST", Serial3.InputStream, Serial3.OutputStream)
		flagIsConn = True
		flagConnError = ""
		Serial3.Listen
	Else
		flagIsConn = False
		flagConnError = LastException.Message
	End If
	If SubExists(mySender, "btHuskylens_Connected") Then
		CallSub2(mySender, "btHuskylens_Connected", Success) 'ignore
	End If
End Sub
#End Region

#Region Internal_AsyncStream_Events
' Internal AsyncStream Events
' This event would keep interacting with bluetooth scale (i.e. very busy) until the service is terminated
' Refresh to UI by CallSub2 in consumer activity or page only the receiving text is different from before.
' Thus, asynchronous of I/O interaction is achieved by this service to relieve the bundle of activity
Private Sub AST_NewText (Text As String, idx As Int) 
	' parameter idx is close curly Index	
	If Text.Length-1 = idx Then
		If currText = Text Then
			' No change in coming message
			' Most of time sending same message when the Huskylens is in idle
			Return
		End If
	Else
		If currText = Text.SubString2(0, idx+1) Then
			' No change in coming message
			' Most of time sending same message when the Huskylens is in idle
			Return
		End If
	End If		
	Log("Data " & Text)
	' Update the current reading
	If Text.Length-1 = idx Then
		currText = Text
	Else
		currText = Text.SubString2(0, idx+1)
	End If	
	Dim mapResult As Map = parseJson(currText)
	If mapResult.IsInitialized And mapResult.ContainsKey("id") Then
		' Log("Message received: " & Text)
		If currId <> mapResult.Get("id").As(Int) Then
			currId = mapResult.Get("id").As(Int)
			LogColor("Huskylens identify object Id: " & currId, Colors.Magenta)
		End If
	End If
	If SubExists(mySender, "btHuskylens_NewText") Then
		CallSub2(mySender, "btHuskylens_NewText", currId) 'ignore
	End If
End Sub

Private Sub AST_Error
	If SubExists(mySender, "btHuskylens_Error") Then
		CallSub(mySender, "btHuskylens_Error") 'ignore
	End If
End Sub

Private Sub AST_Terminated
	flagIsConn = False
	If SubExists(mySender, "btHuskylens_Terminated") Then
		CallSub(mySender, "btHuskylens_Terminated") 'ignore
	End If
End Sub
#End Region

Private Sub parseJson(jstr As String) As Map
	Dim jParser As JSONParser
	Try
		jParser.Initialize(jstr)
		Dim m As Map = jParser.NextObject
		Return m
	Catch
		LogColor("svcSerialHuskylens.parseJson: " & CRLF & LastException.Message, Colors.Red)
		Return CreateMap()
	End Try
End Sub
