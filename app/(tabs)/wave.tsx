import React, { useState } from "react";
import { ScrollView, Text, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "../../src/theme";

export default function Wave() {
 const { palette } = useTheme();
 const [attempted, setAttempted] = useState(false);
 return <ScrollView style={{flex:1,backgroundColor:palette.bg}} contentContainerStyle={{paddingTop:58,paddingHorizontal:20,paddingBottom:30}}>
  <Text style={{color:palette.muted,fontSize:11,letterSpacing:2}}>ПЕРСОНАЛЬНОЕ РАДИО</Text>
  <Text style={{color:palette.text,fontSize:34,fontWeight:"800",letterSpacing:-1,marginTop:5}}>Моя волна</Text>
  <View style={{height:360,borderRadius:28,marginTop:22,backgroundColor:palette.elevated,alignItems:"center",justifyContent:"center",padding:28,overflow:"hidden"}}>
   <View style={{width:180,height:180,borderRadius:90,alignItems:"center",justifyContent:"center",backgroundColor:palette.dark?"#211D3A":"#E5E0FF",borderWidth:1,borderColor:palette.line}}>
    <Ionicons name="radio" size={70} color={palette.accent}/>
    <View style={{position:"absolute",width:210,height:210,borderRadius:105,borderWidth:1,borderColor:palette.accent,opacity:.22}}/>
   </View>
   <Text style={{color:palette.text,fontSize:23,fontWeight:"800",marginTop:24,textAlign:"center"}}>{attempted?"Нужен музыкальный источник":"Твоя музыка — на ходу"}</Text>
   <Text style={{color:palette.muted,fontSize:13,textAlign:"center",marginTop:9,lineHeight:20}}>{attempted?"Радио не подменяет рекомендации фиксированным списком. Сначала нужно подключить каталог с разрешённым воспроизведением.":"Rhythm будет запрашивать следующий трек по мере прослушивания, учитывая лайки, пропуски и историю. Никакого постоянного плейлиста."}</Text>
   <Pressable onPress={()=>setAttempted(true)} style={{height:48,marginTop:20,paddingHorizontal:22,borderRadius:24,backgroundColor:palette.accent,flexDirection:"row",alignItems:"center",gap:8}}>
    <Ionicons name="radio-outline" size={18} color={palette.onAccent}/><Text style={{color:palette.onAccent,fontWeight:"800"}}>{attempted?"Источник ещё не подключён":"Подготовить радио"}</Text>
   </Pressable>
  </View>
  <View style={{marginTop:24,padding:16,borderRadius:18,borderWidth:1,borderColor:palette.line,backgroundColor:palette.surface}}>
   <Text style={{color:palette.text,fontSize:15,fontWeight:"800"}}>Как будет работать волна</Text>
   {["Запрос новой рекомендации после каждого трека","Исключение недавних повторов и пропусков","Учет лайков, исполнителей и музыкального настроения"].map((label,i)=><View key={label} style={{flexDirection:"row",alignItems:"center",gap:10,marginTop:13}}><Ionicons name="checkmark-circle" size={19} color={palette.accent}/><Text style={{color:palette.muted,fontSize:12,flex:1,lineHeight:18}}>{label}</Text></View>)}
  </View>
  <Text style={{color:palette.muted,fontSize:11,lineHeight:17,marginTop:15}}>Сейчас экран честно показывает состояние прототипа. Для реальных новых треков требуется подключить API каталога и источник, разрешающий воспроизведение.</Text>
 </ScrollView>;
}
