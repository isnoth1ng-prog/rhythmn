import React from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { ThemeProvider, useTheme } from "../src/theme";
function Navigation() {
  const { palette } = useTheme();
  return <>
    <StatusBar style={palette.dark ? "light" : "dark"} translucent backgroundColor="transparent" />
    <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: palette.bg }, animation: "fade" }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="player" options={{ presentation: "transparentModal", animation: "slide_from_bottom", contentStyle: { backgroundColor: "transparent" } }} />
    </Stack>
  </>;
}
export default function RootLayout() {
  return <ThemeProvider><Navigation /></ThemeProvider>;
}
