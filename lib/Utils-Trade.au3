#include-once

;~ Wrapper function for the item filter requested by the user.
;~ Falls back to DefaultShouldStoreItem if the specific name is not found.
Func ShouldKeepItem($item)
	; The user mentioned ShutKeepItem, assuming it's a typo or a custom function they want to use.
	; In this codebase, DefaultShouldStoreItem seems to be the one deciding what goes to storage.
	Return DefaultShouldStoreItem($item)
EndFunc

;~ Main method to trade items to the character at the specified coordinates
Func TradeWithPylosAlect()
	Local $targetX = 5122
	Local $targetY = 9035
	Local $playerName = "Trading Partner"
	
	; Rendering sicherstellen vor Teleport
	If Not GetIsRendering() Then
		Warn("Rendering ist deaktiviert. Aktiviere Rendering vor Teleport.")
		EnableRendering()
		Sleep(1000)
	EndIf
	
	; Gegebenenfalls in die Gildenhalle teleportieren
	If GetMapID() <> 6 Then
		Warn("Teleportiere zur Gildenhalle für Handel.")
		TravelGuildHall()
		Sleep(2000)
	EndIf

	; Agenten bei Koordinaten suchen (Range 300)
	Local $agent = GetNearestAgentToCoords($targetX, $targetY, $ID_AGENT_TYPE_NPC)
	
	If Not IsDllStruct($agent) Then
		Warn("Konnte keinen Handelspartner in der Nähe der Koordinaten finden.")
		Return False
	EndIf

	Local $dist = GetDistanceToPoint($agent, $targetX, $targetY)
	If $dist > 300 Then
		Warn("Kein Handelspartner in Range 300 gefunden (Nächster ist " & Round($dist) & " Einheiten entfernt).")
		Return False
	EndIf
	
	$playerName = GetPlayerName($agent)
	If $playerName == "" Then $playerName = "Unbekannter Spieler"

	; Bewege mich zum Zielpunkt, falls nötig
	Local $me = GetMyAgent()
	Local $myDist = GetDistanceToPoint($me, $targetX, $targetY)
	If $myDist > 500 Then
		Warn("Bewege mich zu den Handelskoordinaten (Distanz: " & Round($myDist) & ").")
		MoveTo($targetX, $targetY)
		Sleep(2000)
	EndIf
	
	Local $itemsToTrade[0][3]
	
	; Bags 1-5 (Inventory) and 8-21 (Storage)
	Local $bagsToSearch[] = [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
	
	For $bagIndex In $bagsToSearch
		Local $bag = GetBag($bagIndex)
		If $bag == 0 Then ContinueLoop
		Local $slots = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $slots
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
			
			If ShouldKeepItem($item) Then
				ReDim $itemsToTrade[UBound($itemsToTrade) + 1][3]
				$itemsToTrade[UBound($itemsToTrade) - 1][0] = DllStructGetData($item, 'ID')
				$itemsToTrade[UBound($itemsToTrade) - 1][1] = DllStructGetData($item, 'Quantity')
				$itemsToTrade[UBound($itemsToTrade) - 1][2] = $playerName
			EndIf
		Next
	Next
	
	Local $totalItems = UBound($itemsToTrade)
	If $totalItems == 0 Then
		Debug("Keine Items zum Traden gefunden.")
		Return True
	EndIf
	
	Debug($totalItems & " Items zum Traden mit " & $playerName & " gefunden.")
	
	Local $itemIndex = 0
	While $itemIndex < $totalItems
		; Open trade
		TradePlayer($agent)
		Sleep(1000 + GetPing())
		
		Local $itemsInThisTrade = 0
		While $itemsInThisTrade < 7 And $itemIndex < $totalItems
			OfferItem($itemsToTrade[$itemIndex][0], $itemsToTrade[$itemIndex][1])
			Sleep(200 + GetPing())
			$itemsInThisTrade += 1
			$itemIndex += 1
		WEnd
		
		; Submit offer (Ja)
		SubmitOffer(0)
		Sleep(1000 + GetPing())
		
		; Accept trade (Handel abschließen)
		AcceptTrade()
		Sleep(1000 + GetPing())
		
		If $itemIndex < $totalItems Then
			Debug("Handel abgeschlossen, warte 2 Sekunden auf den nächsten...")
			Sleep(2000)
		EndIf
	WEnd
	
	Warn("Handel mit " & $playerName & " beendet.")
	Return True
EndFunc
