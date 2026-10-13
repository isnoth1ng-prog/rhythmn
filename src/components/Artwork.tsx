import React from "react";
import { Image, StyleSheet, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
export function Artwork({ uri, size, radius = 14 }: { uri: string; size: number; radius?: number }) {
  return <View style={[styles.wrap, { width: size, height: size, borderRadius: radius }]}>
    <Image source={{ uri }} style={{ width: size, height: size, borderRadius: radius }} />
    <LinearGradient colors={["rgba(255,255,255,0.12)", "transparent", "rgba(0,0,0,0.2)"]} style={[StyleSheet.absoluteFill, { borderRadius: radius }]} />
  </View>;
}
const styles = StyleSheet.create({ wrap: { overflow: "hidden", backgroundColor: "#242333" } });
