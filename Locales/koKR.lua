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
	["PotCheck"]					= "물약 확인",
	["Check for lust pot"]			= "블러드 후 물약 확인",
	["ClassColors"]					= "직업 색상",
	["Show class colors"]			= "직업 색상 표시",
	["SendtoChat"]					= "물약 체크 결과 공대경보나 공대채널로 보내기",
	["Send to RW or Raid chat"]		= "확인 결과를 공장이나 부공일 경우 경보로, 아니면 공대채널로 보내기",
	["MSG0"]						= "[%.2f초 후 물약 없음]: %s",
	["MSG1"]						= "[%s]님 블러드 시전! 그러나 물약은 쿨...",
	["MSG2"]						= "[%s]님 블러드 시전! 물약 잡주세요!!",
	["NONE"]						= "전딜진 마심.",
	["General Options"]				= "일반 설정",
	["Seconds after lust to check"] = "블러드 시전 몇초 후에 물약 체크",
}

ns:RegisterLocale("koKR", translations)
translations = nil