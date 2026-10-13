import React from "react";
import { ScrollView, Text, View, Pressable, ImageBackground, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "../../src/theme";
import { Artwork } from "../../src/components/Artwork";
import { SAMPLE_TRACK, STARTER_TRACKS } from "../../src/data";
export default function Home() {
  const { palette } = useTheme(); const router = useRouter();
  return <ScrollView style={{ flex: 1, backgroundColor: palette.bg }} contentContainerStyle={{ paddingTop: 54, paddingHorizontal: 20, paddingBottom: 24 }}>
    <View style={styles.top}><View><Text style={{ color: palette.muted, fontSize: 12, letterSpacing: 2 }}>ТВОЙ ЗВУК</Text><Text style={{ color: palette.text, fontSize: 32, fontWeight: "800", letterSpacing: -1 }}>Rhythm</Text></View><Pressable onPress={() => router.push("/(tabs)/settings")} style={[styles.avatar, { backgroundColor: palette.elevated }]}><Ionicons name="person-outline" size={20} color={palette.text}/></Pressable></View>
    <Pressable onPress={() => router.push("/(tabs)/wave")} style={[styles.hero, { backgroundColor: palette.elevated }]}>
      <ImageBackground source={{ uri: "https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=1200&q=90" }} imageStyle={{ borderRadius: 26, opacity: .75 }} style={styles.heroInner}>
        <View style={styles.heroShade}><View style={[styles.waveIcon, { backgroundColor: palette.accent }]}><Ionicons name="radio" size={23} color={palette.onAccent}/></View><Text style={styles.heroTitle}>Твоя волна</Text><Text style={styles.heroText}>Музыка, которая попадает в настроение</Text><View style={styles.playBadge}><Ionicons name="play" size={18} color="#101018"/></View></View>
      </ImageBackground>
    </Pressable>
    <View style={styles.sectionHead}><Text style={[styles.sectionTitle, { color: palette.text }]}>Продолжить</Text><Text style={{ color: palette.accent, fontSize: 12 }}>Для тебя</Text></View>
    <Pressable onPress={() => router.push("/player")} style={[styles.feature, { backgroundColor: palette.surface, borderColor: palette.line }]}><Artwork uri={SAMPLE_TRACK.art} size={76} radius={15}/><View style={{ flex: 1, marginLeft: 14 }}><Text style={{ color: palette.muted, fontSize: 11 }}>ПРОВЕРКА ПЛЕЕРА · ДЕМО</Text><Text style={{ color: palette.text, fontSize: 16, fontWeight: "700", marginTop: 4 }}>{SAMPLE_TRACK.title}</Text><Text style={{ color: palette.muted, marginTop: 3, fontSize: 12 }}>{SAMPLE_TRACK.artist}</Text></View><Ionicons name="play-circle" size={34} color={palette.accent}/></Pressable>
    <View style={styles.sectionHead}><Text style={[styles.sectionTitle, { color: palette.text }]}>Под настроение</Text><Pressable onPress={() => router.push("/(tabs)/wave")}><Text style={{ color: palette.accent }}>Открыть волну</Text></Pressable></View>
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 13 }}>
      {STARTER_TRACKS.slice(1).map(track => <Pressable key={track.id} onPress={() => router.push("/player")} style={{ width: 142 }}><Artwork uri={track.art} size={142} radius={18}/><Text numberOfLines={1} style={{ color: palette.text, fontWeight: "700", marginTop: 9 }}>{track.title}</Text><Text numberOfLines={1} style={{ color: palette.muted, fontSize: 12, marginTop: 3 }}>{track.artist}</Text></Pressable>)}
    </ScrollView>
    <Text style={{ color: palette.muted, fontSize: 11, marginTop: 26, textAlign: "center" }}>Прототип · демо-контент не является музыкальным каталогом</Text>
  </ScrollView>;
}
const styles = StyleSheet.create({
 top:{flexDirection:"row",alignItems:"center",justifyContent:"space-between",marginBottom:24},
 avatar:{width:42,height:42,borderRadius:21,alignItems:"center",justifyContent:"center"},
 hero:{height:218,borderRadius:26,overflow:"hidden",marginBottom:28},
 heroInner:{flex:1},
 heroShade:{flex:1,backgroundColor:"rgba(8,8,18,0.22)",padding:20,justifyContent:"flex-end"},
 waveIcon:{width:42,height:42,borderRadius:21,alignItems:"center",justifyContent:"center",marginBottom:14},
 heroTitle:{fontSize:28,fontWeight:"800",color:"white",letterSpacing:-.6},
 heroText:{fontSize:13,color:"rgba(255,255,255,.78)",marginTop:5},
 playBadge:{position:"absolute",right:18,bottom:20,width:42,height:42,borderRadius:21,backgroundColor:"#F8F5FF",alignItems:"center",justifyContent:"center"},
 sectionHead:{flexDirection:"row",alignItems:"center",justifyContent:"space-between",marginBottom:14,marginTop:2},
 sectionTitle:{fontSize:20,fontWeight:"800",letterSpacing:-.4},
 feature:{flexDirection:"row",alignItems:"center",borderRadius:20,borderWidth:1,padding:11,marginBottom:27}
});
