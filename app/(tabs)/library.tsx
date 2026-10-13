import React from "react";
import { ScrollView, Text, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useTheme } from "../../src/theme";
import { Artwork } from "../../src/components/Artwork";
import { STARTER_TRACKS } from "../../src/data";
export default function Library(){
 const {palette}=useTheme(); const router=useRouter();
 const rows=[["heart","Любимые треки","Пока пусто"],["time","История прослушиваний","Недавно прослушанное"],["albums","Плейлисты","Создай свою подборку"]];
 return <ScrollView style={{flex:1,backgroundColor:palette.bg}} contentContainerStyle={{paddingTop:58,paddingHorizontal:20,paddingBottom:30}}>
  <Text style={{color:palette.text,fontSize:32,fontWeight:"800",letterSpacing:-1,marginBottom:24}}>Медиатека</Text>
  {rows.map(([icon,title,sub])=><Pressable key={title} style={{flexDirection:"row",alignItems:"center",paddingVertical:15,borderBottomWidth:1,borderBottomColor:palette.line,gap:13}}><View style={{width:45,height:45,borderRadius:15,backgroundColor:palette.elevated,alignItems:"center",justifyContent:"center"}}><Ionicons name={icon as any} size={21} color={palette.accent}/></View><View style={{flex:1}}><Text style={{color:palette.text,fontWeight:"700",fontSize:15}}>{title}</Text><Text style={{color:palette.muted,fontSize:12,marginTop:4}}>{sub}</Text></View><Ionicons name="chevron-forward" size={18} color={palette.muted}/></Pressable>)}
  <Text style={{color:palette.text,fontSize:20,fontWeight:"800",marginTop:30,marginBottom:14}}>Недавно добавлено</Text>
  {STARTER_TRACKS.map(track=><Pressable key={track.id} onPress={()=>router.push("/player")} style={{flexDirection:"row",alignItems:"center",gap:12,paddingVertical:8}}><Artwork uri={track.art} size={54} radius={12}/><View style={{flex:1}}><Text style={{color:palette.text,fontWeight:"700"}}>{track.title}</Text><Text style={{color:palette.muted,fontSize:12,marginTop:3}}>{track.artist} · {track.demo?"демо":"трек"}</Text></View><Ionicons name="ellipsis-horizontal" size={19} color={palette.muted}/></Pressable>)}
 </ScrollView>;
}
