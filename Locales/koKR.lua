local _, ns = ...

local translations = {
	["Pot Reminder"] 				= "물약 잊지말자",
	["Enable"]						= "활성화",
	["Toggle addon enable"]			= "애드온 켜기/끄기",
	["LFR"]							= "공격대 찾기",
	["Enable in LFR"]				= "공격대 찾기 난이도에서 활성화",
	["Normal"]						= "일반",
	["Enable in Normal mode"]		= "일반 난이도에서 활성화",
	["Enable Sound"]				= "소리 알림 활성화",
	["ChatAlert"]					= "채팅창에 알림",
	["Alert to chat"]				= "채팅창에도 알림 메세지",
	["MSG1"]						= "[%s]님 블러드 시전! 그러나 물약은 쿨...",
	["MSG2"]						= "[%s]님 블러드 시전! 물약 잡주세요!!",
	["General Options"]				= "일반 설정",
}

ns:RegisterLocale("koKR", translations)
translations = nil