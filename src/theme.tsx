import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { useColorScheme } from "react-native";

export type Appearance = "system" | "dark" | "light";
export const ACCENTS = [
  { name: "Violet", value: "#9A7BFF" },
  { name: "Blue", value: "#6D9CFF" },
  { name: "Mint", value: "#72E4C1" },
  { name: "Rose", value: "#FF79B8" },
  { name: "Amber", value: "#FFC56E" }
];
export type Palette = {
  dark: boolean; bg: string; surface: string; elevated: string; text: string;
  muted: string; line: string; accent: string; onAccent: string;
};
type ThemeContextValue = { appearance: Appearance; setAppearance: (v: Appearance) => void; accent: string; setAccent: (v: string) => void; palette: Palette };
const Context = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const system = useColorScheme();
  const [appearance, setAppearance] = useState<Appearance>("dark");
  const [accent, setAccent] = useState(ACCENTS[0].value);
  const [ready, setReady] = useState(false);
  useEffect(() => {
    AsyncStorage.multiGet(["rhythm.appearance", "rhythm.accent"]).then(values => {
      if (values[0][1] === "system" || values[0][1] === "dark" || values[0][1] === "light") setAppearance(values[0][1]);
      if (values[1][1] && ACCENTS.some(a => a.value === values[1][1])) setAccent(values[1][1]!);
    }).catch(() => undefined).finally(() => setReady(true));
  }, []);
  useEffect(() => { if (ready) AsyncStorage.setItem("rhythm.appearance", appearance).catch(() => undefined); }, [appearance, ready]);
  useEffect(() => { if (ready) AsyncStorage.setItem("rhythm.accent", accent).catch(() => undefined); }, [accent, ready]);
  const dark = appearance === "system" ? system !== "light" : appearance === "dark";
  const palette = useMemo<Palette>(() => dark ? {
    dark: true, bg: "#08090D", surface: "#11131A", elevated: "#1A1D27", text: "#F7F6FC",
    muted: "#9698AA", line: "rgba(255,255,255,0.09)", accent, onAccent: "#08090D"
  } : {
    dark: false, bg: "#F5F5FA", surface: "#FFFFFF", elevated: "#EBECF4", text: "#171823",
    muted: "#77798C", line: "rgba(20,20,35,0.10)", accent, onAccent: "#FFFFFF"
  }, [dark, accent]);
  return <Context.Provider value={{ appearance, setAppearance, accent, setAccent, palette }}>{children}</Context.Provider>;
}
export function useTheme() {
  const value = useContext(Context);
  if (!value) throw new Error("useTheme must be used inside ThemeProvider");
  return value;
}
