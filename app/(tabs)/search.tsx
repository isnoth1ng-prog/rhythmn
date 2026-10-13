import React, { useMemo, useState } from "react";
import { ScrollView, Text, TextInput, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useTheme } from "../../src/theme";
import { Artwork } from "../../src/components/Artwork";
import { STARTER_TRACKS } from "../../src/data";
const normalize = (value: string) => value.toLowerCase().replace(/[^a-z0-9а-яё]+/gi, " ").trim();
export default function Search() {
 const { palette } = useTheme(); const router = useRouter(); const [query, setQuery] = useState("");
 const results = useMemo(() => {
  const q = normalize(query);
  return STARTER_TRACKS.filter(track => !q || normalize(track.title + " " + track.artist).includes(q))
   .sort((a,b) => Number(normalize(b.title + " " + b.artist).startsWith(q)) - Number(normalize(a.title + " " + a.artist).startsWith(q)));
 }, [query]);
 return <ScrollView style={{flex:1,backgroundColor:palette.bg}} contentContainerStyle={{paddingTop:58,paddingHorizontal:20,paddingBottom:28}}>
  <Text style={{color:palette.text,fontSize:32,fontWeight:"800",letterSpacing:-1,marginBottom:20}}>Поиск</Text>
  <View style={{height:52,borderRadius:16,backgroundColor:palette.elevated,flexDirection:"row",alignItems:"center",paddingHorizontal:15,marginBottom:24}}>
   <Ionicons name="search" size={20} color={palette.muted}/><TextInput value={query} onChangeText={setQuery} placeholder="Трек, исполнитель или альбом" placeholderTextColor={palette.muted} returnKeyType="search" style={{flex:1,color:palette.text,marginLeft:10,fontSize:14}}/><Pressable onPress={()=>setQuery("")}><Ionicons name="close-circle" size={18} color={palette.muted}/></Pressable>
  </View>
  <Text style={{color:palette.muted,fontSize:11,letterSpacing:1.5,marginBottom:13}}>{query?"РЕЗУЛЬТАТЫ · ДЕМО":"ПОИСК ПО ПРОТОТИПУ"}</Text>
  {results.length ? results.map(track=><Pressable key={track.id} onPress={()=>router.push("/player")} style={{flexDirection:"row",alignItems:"center",paddingVertical:9,gap:12}}><Artwork uri={track.art} size={58} radius={12}/><View style={{flex:1}}><Text style={{color:palette.text,fontSize:15,fontWeight:"700"}}>{track.title}</Text><Text style={{color:palette.muted,fontSize:12,marginTop:4}}>{track.artist} · демо</Text></View><Ionicons name="ellipsis-horizontal" size={20} color={palette.muted}/></Pressable>) : <View style={{alignItems:"center",padding:30}}><Ionicons name="search-outline" size={36} color={palette.muted}/><Text style={{color:palette.text,fontWeight:"700",marginTop:12}}>Ничего не найдено</Text><Text style={{color:palette.muted,marginTop:5}}>Попробуй изменить запрос</Text></View>}
 </ScrollView>;
}
