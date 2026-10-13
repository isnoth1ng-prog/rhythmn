import React, { useState } from "react";
import { ScrollView, Text, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useTheme } from "../../src/theme";
import { Artwork } from "../../src/components/Artwork";
import { SAMPLE_TRACK, STARTER_TRACKS } from "../../src/data";
export default function Wave(){
 const {palette}=useTheme(); const router=useRouter(); const [seed,setSeed]=useState(0); const [loading,setLoading]=useState(false);
 const refresh=()=>{setLoading(true);setTimeout(()=>{setSeed(v=>v+1);setLoading(false);},500);};
 const queue=STARTER_TRACKS.slice(1).map((_,i)=>STARTER_TRACKS[1+((i+seed)%Math.max(1,STARTER_TRACKS.length-1))]).filter(Boolean);
 return <ScrollView style={{flex:1,backgroundColor:palette.bg}} contentContainerStyle={{paddingTop:58,paddingHorizontal:20,paddingBottom:30}}>
  <Text style={{color:palette.muted,fontSize:11,letterSpacing:2}}>ПЕРСОНАЛЬНОЕ РАДИО</Text><Text style={{color:palette.text,fontSize:34,fontWeight:"800",letterSpacing:-1,marginTop:5}}>Моя волна</Text>
  <View style={{height:350,borderRadius:28,marginTop:22,backgroundColor:palette.elevated,alignItems:"center",justifyContent:"center",padding:24,overflow:"hidden"}}>
   <Artwork uri={SAMPLE_TRACK.art} size={220} radius={110}/>
   <View style={{position:"absolute",top:22,left:22,right:22,bottom:22,borderRadius:22,borderWidth:1,borderColor:"rgba(255,255,255,.12)"}}/>
   <Text style={{color:palette.text,fontSize:23,fontWeight:"800",marginTop:20}}>Собираем твой звук</Text><Text style={{color:palette.muted,fontSize:13,textAlign:"center",marginTop:7,lineHeight:20}}>В будущем очередь будет строиться по твоим лайкам, истории и пропускам — не по постоянному списку.</Text>
   <Pressable onPress={refresh} style={{height:48,marginTop:18,paddingHorizontal:24,borderRadius:24,backgroundColor:palette.accent,flexDirection:"row",alignItems:"center",gap:8}}><Ionicons name={loading?"sync":"play"} size={18} color={palette.onAccent}/><Text style={{color:palette.onAccent,fontWeight:"800"}}>{loading?"Обновляем…":"Запустить демо-волну"}</Text></Pressable>
  </View>
  <View style={{flexDirection:"row",alignItems:"center",justifyContent:"space-between",marginTop:28,marginBottom:12}}><Text style={{color:palette.text,fontSize:20,fontWeight:"800"}}>Следом в демо-очереди</Text><Pressable onPress={refresh}><Ionicons name="refresh" size={20} color={palette.accent}/></Pressable></View>
  {queue.map((track,i)=><Pressable key={track.id+seed} onPress={()=>router.push("/player")} style={{flexDirection:"row",alignItems:"center",paddingVertical:9,gap:12}}><Artwork uri={track.art} size={52} radius={12}/><View style={{flex:1}}><Text style={{color:palette.text,fontWeight:"700"}}>{track.title}</Text><Text style={{color:palette.muted,fontSize:12,marginTop:3}}>{track.artist}</Text></View><Text style={{color:palette.muted,fontSize:12}}>{i===0?"Далее":""}</Text></Pressable>)}
  <Text style={{color:palette.muted,fontSize:11,lineHeight:17,marginTop:15}}>Сейчас это UI-прототип: кнопка меняет демо-последовательность, но ещё не подключает рекомендательный сервис и не воспроизводит аудио.</Text>
 </ScrollView>;
}
