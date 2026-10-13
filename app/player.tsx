import React, { useEffect, useRef, useState } from "react";
import { Pressable, ScrollView, Text, View, StyleSheet, useWindowDimensions } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { Audio, AVPlaybackStatus } from "expo-av";
import { BlurView } from "expo-blur";
import { LinearGradient } from "expo-linear-gradient";
import { useTheme } from "../src/theme";
import { Artwork } from "../src/components/Artwork";
import { SAMPLE_TRACK, SAMPLE_LYRICS, formatTime } from "../src/data";

export default function Player() {
 const { palette } = useTheme(); const router = useRouter(); const { height } = useWindowDimensions();
 const sound = useRef<Audio.Sound | null>(null);
 const [elapsed, setElapsed] = useState(0); const [playing, setPlaying] = useState(false);
 const [ready, setReady] = useState(false); const [error, setError] = useState("");
 useEffect(() => {
  let mounted = true;
  Audio.Sound.createAsync({ uri: SAMPLE_TRACK.audioUrl! }, { shouldPlay: false }, (status: AVPlaybackStatus) => {
   if (!status.isLoaded || !mounted) return;
   setElapsed(Math.floor(status.positionMillis / 1000));
   setPlaying(status.isPlaying);
   if (status.didJustFinish) setPlaying(false);
  }).then(({ sound: loaded }) => {
   if (mounted) { sound.current = loaded; setReady(true); }
   else loaded.unloadAsync();
  }).catch(() => { if (mounted) setError("Не удалось загрузить аудио. Проверь подключение к интернету."); });
  return () => { mounted = false; sound.current?.unloadAsync(); sound.current = null; };
 }, []);
 const togglePlayback = async () => {
  try {
   setError("");
   if (!sound.current) { setError("Аудио ещё загружается."); return; }
   if (playing) await sound.current.pauseAsync(); else await sound.current.playAsync();
  } catch { setError("Источник не ответил. Попробуй позже."); }
 };
 const active = SAMPLE_LYRICS.reduce((n,line,i)=>line.time<=elapsed?i:n,0);
 return <View style={{ flex:1, backgroundColor:palette.bg, overflow:"hidden" }}>
  <View style={StyleSheet.absoluteFill}>
   <Artwork uri={SAMPLE_TRACK.art} size={Math.max(height,420)} radius={0}/>
   <BlurView intensity={85} tint={palette.dark?"dark":"light"} style={StyleSheet.absoluteFill}/>
   <LinearGradient colors={palette.dark?["rgba(7,8,15,.55)","rgba(7,8,15,.82)","#08090D"]:["rgba(244,244,250,.5)","rgba(244,244,250,.8)","#F5F5FA"]} style={StyleSheet.absoluteFill}/>
  </View>
  <View style={{paddingTop:48,paddingHorizontal:22,flexDirection:"row",alignItems:"center",justifyContent:"space-between"}}>
   <Pressable onPress={()=>router.back()} hitSlop={12}><Ionicons name="chevron-down" size={27} color={palette.text}/></Pressable>
   <View style={{alignItems:"center"}}><Text style={{color:palette.muted,fontSize:10,letterSpacing:1.5}}>СЕЙЧАС ИГРАЕТ</Text><Text style={{color:palette.text,fontSize:13,fontWeight:"700",marginTop:4}}>Rhythm · ТЕСТОВЫЙ ТРЕК</Text></View>
   <Pressable hitSlop={12}><Ionicons name="ellipsis-horizontal" size={23} color={palette.text}/></Pressable>
  </View>
  <ScrollView style={{flex:1,marginTop:14}} contentContainerStyle={{alignItems:"center",paddingHorizontal:26,paddingBottom:18}}>
   <Artwork uri={SAMPLE_TRACK.art} size={Math.min(220,height*.25)} radius={22}/>
   <Text style={{color:palette.text,fontSize:24,fontWeight:"800",letterSpacing:-.5,marginTop:17,textAlign:"center"}}>{SAMPLE_TRACK.title}</Text>
   <Text style={{color:palette.muted,fontSize:13,marginTop:5,textAlign:"center"}}>{SAMPLE_TRACK.artist}</Text>
   <Text style={{color:palette.muted,fontSize:10,marginTop:5,textAlign:"center"}}>Wikimedia Commons · CC BY-SA 3.0 / GFDL</Text>
   <View style={{width:"100%",marginTop:22,marginBottom:15}}>
    <View style={{height:3,borderRadius:2,backgroundColor:palette.line,overflow:"hidden"}}><View style={{height:3,width:`${Math.min(100,elapsed/SAMPLE_TRACK.duration*100)}%`,backgroundColor:palette.accent}}/></View>
    <View style={{flexDirection:"row",justifyContent:"space-between",marginTop:8}}><Text style={{color:palette.muted,fontSize:11}}>{formatTime(elapsed)}</Text><Text style={{color:palette.muted,fontSize:11}}>{formatTime(SAMPLE_TRACK.duration)}</Text></View>
   </View>
   <View style={{width:"100%",marginTop:1,marginBottom:14}}>
    <Text style={{color:palette.muted,fontSize:10,letterSpacing:2,textAlign:"center",marginBottom:10}}>ТЕКСТ ПЕСНИ</Text>
    {SAMPLE_LYRICS.map((line,i)=>{
     const current=i===active;
     return <Text key={line.time} style={{color:current?palette.text:palette.muted,opacity:current?1:(i<active?0.32:0.58),fontSize:current?21:17,fontWeight:current?"800":"600",lineHeight:current?29:27,textAlign:"center",marginVertical:6,transform:[{scale:current?1:0.98}]}}>{line.text}</Text>;
    })}
    <Text style={{color:palette.muted,fontSize:10,textAlign:"center",marginTop:10}}>Традиционный текст · тайминг примерный, для проверки интерфейса</Text>
   </View>
  </ScrollView>
  <View style={{paddingHorizontal:28,paddingTop:12,paddingBottom:25,backgroundColor:palette.dark?"rgba(8,9,13,.45)":"rgba(245,245,250,.55)"}}>
   {error ? <Text style={{color:"#FF8A8A",fontSize:12,textAlign:"center",marginBottom:8}}>{error}</Text> : null}
   <View style={{flexDirection:"row",alignItems:"center",justifyContent:"space-between"}}>
    <Pressable accessibilityLabel="Перемешать" disabled><Ionicons name="shuffle" size={22} color={palette.muted}/></Pressable>
    <Pressable accessibilityLabel="Предыдущий трек" disabled><Ionicons name="play-skip-back" size={26} color={palette.muted}/></Pressable>
    <Pressable onPress={togglePlayback} style={{width:62,height:62,borderRadius:31,backgroundColor:palette.accent,alignItems:"center",justifyContent:"center"}}><Ionicons name={playing?"pause":"play"} size={27} color={palette.onAccent}/></Pressable>
    <Pressable accessibilityLabel="Следующий трек" disabled><Ionicons name="play-skip-forward" size={26} color={palette.muted}/></Pressable>
    <Pressable accessibilityLabel="Добавить в избранное" disabled><Ionicons name="heart-outline" size={23} color={palette.muted}/></Pressable>
   </View>
   <Text style={{color:palette.muted,fontSize:10,textAlign:"center",marginTop:9}}>{ready?"Тестовая запись · воспроизведение из Wikimedia Commons":"Подключаем тестовую запись…"}</Text>
  </View>
 </View>;
}
