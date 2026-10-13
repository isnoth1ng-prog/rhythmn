import React, { useEffect, useState } from "react";
import { Modal, Pressable, ScrollView, Text, View, StyleSheet, useWindowDimensions } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { BlurView } from "expo-blur";
import { LinearGradient } from "expo-linear-gradient";
import { useTheme } from "../src/theme";
import { Artwork } from "../src/components/Artwork";
import { SAMPLE_TRACK, SAMPLE_LYRICS, formatTime } from "../src/data";

export default function Player() {
 const { palette } = useTheme(); const router = useRouter(); const { height } = useWindowDimensions();
 const [elapsed, setElapsed] = useState(0); const [playing, setPlaying] = useState(false);
 useEffect(() => { if (!playing) return; const id = setInterval(() => setElapsed(v => v >= SAMPLE_TRACK.duration ? 0 : v + 1), 1000); return () => clearInterval(id); }, [playing]);
 const active = SAMPLE_LYRICS.reduce((n,line,i)=>line.time<=elapsed?i:n,0);
 return <View style={{ flex:1, backgroundColor:palette.bg, overflow:"hidden" }}>
  <View style={StyleSheet.absoluteFill}>
   <Artwork uri={SAMPLE_TRACK.art} size={Math.max(height,420)} radius={0}/>
   <BlurView intensity={85} tint={palette.dark?"dark":"light"} style={StyleSheet.absoluteFill}/>
   <LinearGradient colors={palette.dark?["rgba(7,8,15,.55)","rgba(7,8,15,.82)","#08090D"]:["rgba(244,244,250,.5)","rgba(244,244,250,.8)","#F5F5FA"]} style={StyleSheet.absoluteFill}/>
  </View>
  <View style={{paddingTop:54,paddingHorizontal:22,flexDirection:"row",alignItems:"center",justifyContent:"space-between"}}>
   <Pressable onPress={()=>router.back()} hitSlop={12}><Ionicons name="chevron-down" size={27} color={palette.text}/></Pressable>
   <View style={{alignItems:"center"}}><Text style={{color:palette.muted,fontSize:10,letterSpacing:1.5}}>СЕЙЧАС ИГРАЕТ</Text><Text style={{color:palette.text,fontSize:13,fontWeight:"700",marginTop:4}}>Rhythm · ДЕМО</Text></View>
   <Pressable hitSlop={12}><Ionicons name="ellipsis-horizontal" size={23} color={palette.text}/></Pressable>
  </View>
  <ScrollView style={{flex:1,marginTop:20}} contentContainerStyle={{alignItems:"center",paddingHorizontal:26,paddingBottom:18}}>
   <Artwork uri={SAMPLE_TRACK.art} size={Math.min(250,height*.29)} radius={22}/>
   <Text style={{color:palette.text,fontSize:24,fontWeight:"800",letterSpacing:-.5,marginTop:20,textAlign:"center"}}>{SAMPLE_TRACK.title}</Text>
   <Text style={{color:palette.muted,fontSize:14,marginTop:5}}>{SAMPLE_TRACK.artist}</Text>
   <View style={{width:"100%",marginTop:25,marginBottom:20}}>
    <View style={{height:3,borderRadius:2,backgroundColor:palette.line,overflow:"hidden"}}><View style={{height:3,width:`${Math.min(100,elapsed/SAMPLE_TRACK.duration*100)}%`,backgroundColor:palette.accent}}/></View>
    <View style={{flexDirection:"row",justifyContent:"space-between",marginTop:8}}><Text style={{color:palette.muted,fontSize:11}}>{formatTime(elapsed)}</Text><Text style={{color:palette.muted,fontSize:11}}>{formatTime(SAMPLE_TRACK.duration)}</Text></View>
   </View>
   <View style={{width:"100%",marginTop:2,marginBottom:16}}>
    <Text style={{color:palette.muted,fontSize:10,letterSpacing:2,textAlign:"center",marginBottom:13}}>ТЕКСТ ПЕСНИ · ДЕМО</Text>
    {SAMPLE_LYRICS.map((line,i)=>{
     const current=i===active;
     return <Text key={line.time} style={{color:current?palette.text:palette.muted,opacity:current?1:i<active?.32:.58,fontSize:current?22:18,fontWeight:current?"800":"600",lineHeight:current?29:28,textAlign:"center",marginVertical:7,transform:[{scale:current?1:0.98}]}}>{line.text}</Text>;
    })}
    <Text style={{color:palette.muted,fontSize:10,textAlign:"center",marginTop:10}}>Демонстрационные строки. Аудио пока не подключено.</Text>
   </View>
  </ScrollView>
  <View style={{paddingHorizontal:28,paddingTop:12,paddingBottom:28,backgroundColor:palette.dark?"rgba(8,9,13,.45)":"rgba(245,245,250,.55)"}}>
   <View style={{flexDirection:"row",alignItems:"center",justifyContent:"space-between"}}>
    <Pressable><Ionicons name="shuffle" size={22} color={palette.muted}/></Pressable>
    <Pressable><Ionicons name="play-skip-back" size={26} color={palette.text}/></Pressable>
    <Pressable onPress={()=>setPlaying(v=>!v)} style={{width:62,height:62,borderRadius:31,backgroundColor:palette.accent,alignItems:"center",justifyContent:"center"}}><Ionicons name={playing?"pause":"play"} size={27} color={palette.onAccent}/></Pressable>
    <Pressable><Ionicons name="play-skip-forward" size={26} color={palette.text}/></Pressable>
    <Pressable><Ionicons name="heart-outline" size={23} color={palette.muted}/></Pressable>
   </View>
   <Text style={{color:palette.muted,fontSize:10,textAlign:"center",marginTop:10}}>Таймер показывает демо-позицию, это не настоящее воспроизведение</Text>
  </View>
 </View>;
}
