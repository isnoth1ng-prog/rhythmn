import React from "react";
import { Tabs, useRouter } from "expo-router";
import { View, Text, Pressable, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "../../src/theme";
import { Artwork } from "../../src/components/Artwork";
import { SAMPLE_TRACK } from "../../src/data";

function Dock() {
  const { palette } = useTheme();
  const router = useRouter();
  return <View style={{ backgroundColor: palette.bg }}>
    <Pressable onPress={() => router.push("/player")} style={[styles.mini, { backgroundColor: palette.elevated, borderColor: palette.line }]}>
      <Artwork uri={SAMPLE_TRACK.art} size={42} radius={9} />
      <View style={{ flex: 1, marginLeft: 11 }}>
        <Text numberOfLines={1} style={{ color: palette.text, fontWeight: "700", fontSize: 13 }}>{SAMPLE_TRACK.title}</Text>
        <Text numberOfLines={1} style={{ color: palette.muted, fontSize: 11, marginTop: 2 }}>Демо · {SAMPLE_TRACK.artist}</Text>
      </View>
      <Pressable accessibilityLabel="Воспроизвести" onPress={() => router.push("/player")} hitSlop={10} style={{ padding: 8 }}>
        <Ionicons name="play" size={21} color={palette.text} />
      </Pressable>
      <View style={{ position: "absolute", left: 0, bottom: 0, height: 2, width: "18%", backgroundColor: palette.accent, borderBottomLeftRadius: 10 }} />
    </Pressable>
  </View>;
}
export default function TabLayout() {
  const { palette } = useTheme();
  const tabs = [
    { name: "index", title: "Главная", icon: "home-outline", active: "home" },
    { name: "search", title: "Поиск", icon: "search-outline", active: "search" },
    { name: "wave", title: "Моя волна", icon: "radio-outline", active: "radio" },
    { name: "library", title: "Медиатека", icon: "library-outline", active: "library" },
    { name: "settings", title: "Профиль", icon: "person-outline", active: "person" }
  ] as const;
  return <Tabs tabBar={(props) => <View style={{ backgroundColor: palette.bg, paddingBottom: 2 }}><Dock /><View style={[styles.tabs, { borderTopColor: palette.line }]}>
    {props.state.routes.map((route, index) => {
      const tab = tabs.find(t => t.name === route.name);
      if (!tab) return null;
      const selected = props.state.index === index;
      return <Pressable key={route.key} onPress={() => props.navigation.navigate(route.name)} style={styles.tab} accessibilityRole="tab" accessibilityState={{ selected }}>
        <Ionicons name={(selected ? tab.active : tab.icon) as any} size={22} color={selected ? palette.accent : palette.muted} />
        <Text style={{ color: selected ? palette.accent : palette.muted, fontSize: 10, marginTop: 4, fontWeight: selected ? "700" : "500" }}>{tab.title}</Text>
      </Pressable>;
    })}
  </View></View>} screenOptions={{ headerShown: false, sceneStyle: { backgroundColor: palette.bg } }}>
    {tabs.map(t => <Tabs.Screen key={t.name} name={t.name} options={{ title: t.title }} />)}
  </Tabs>;
}
const styles = StyleSheet.create({
  mini: { height: 58, marginHorizontal: 12, marginBottom: 8, borderWidth: 1, borderRadius: 17, padding: 7, flexDirection: "row", alignItems: "center", overflow: "hidden" },
  tabs: { height: 58, flexDirection: "row", borderTopWidth: StyleSheet.hairlineWidth },
  tab: { flex: 1, alignItems: "center", justifyContent: "center" }
});
