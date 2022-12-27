B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.8
@EndOfDesignText@
Sub Class_Globals
	Private mTarget As Object
	Private mEventName As String
	Private astreams As AsyncStreams
	Public charset As String = "UTF8"
	Private sb As StringBuilder
	' Private currText As String
	Private closeCurlyIndex As Int
End Sub

Public Sub Initialize (TargetModule As Object, EventName As String, In As InputStream, out As OutputStream)
	mTarget = TargetModule
	mEventName = EventName
	astreams.Initialize(In, out, "astreams")
	sb.Initialize
	' currText = ""
	closeCurlyIndex = -1
End Sub

'Sends the text. Note that this method does not add end of line characters.
Public Sub Write(Text As String)
	astreams.Write(Text.GetBytes(charset))
End Sub

Private Sub isReceivedTextValid(text As String) As Boolean
	If text.Length = 0 Then
		Return False
	End If	
	If text.CharAt(0) <> Chr(123) Then ' ASCII code 123 is {
		Return False
	End If
	closeCurlyIndex = text.IndexOf(Chr(125)) ' ASCII code 125 is }
	If closeCurlyIndex = -1 Then
		Return False
	End If
	Return True	
End Sub

Private Sub astreams_NewData (Buffer() As Byte)
	sb.Remove(0, sb.Length)
'	Dim newDataStart As Int = sb.Length
	sb.Append(BytesToString(Buffer, 0, Buffer.Length, charset))
	Dim s As String = sb.ToString	
	If isReceivedTextValid(s) = False Then
		Return 
	End If
'	If currText = s.SubString2(0, closeCurlyIndex) Then
'		Log("Same string is received.")
'		Return 
'	End If	
'	' Update the currText
'	currText = s.SubString2(0, closeCurlyIndex)
'	Log("NewData: " & s)
	If SubExists(mTarget, mEventName & "_NewText") Then
		CallSubDelayed3(mTarget, mEventName & "_NewText", s, closeCurlyIndex)
	End If
End Sub
Private Sub astreams_Terminated
	CallSubDelayed(mTarget, mEventName & "_Terminated")
End Sub

Private Sub astreams_Error
	Log("error: " & LastException)
	astreams.Close
	CallSubDelayed(mTarget, mEventName & "_Terminated")
End Sub

Public Sub Close
	astreams.Close
End Sub