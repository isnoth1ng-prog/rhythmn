import React from "react";
import { ScrollView, Text, View, Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { ACCENTS, Appearance, useTheme } from "../../src/theme";
export default function Settings(){
 const {palette,appearance,setAppearance,accent,setAccent}=useTheme();
 const modes:{id:Appearance;label:string;icon:any}[]=[{id:"system",label:"Как в системе",icon:"phone-portrait-outline"},{id:"dark",label:"Тёмная",icon:"moon-outline"},{id:"light",label:"Светлая",icon:"sunny-outline"}];
 return <ScrollView style={{flex:1,backgroundColor:palette.bg}} contentContainerStyle={{paddingTop:58,paddingHorizontal:20,paddingBottom:30}}>
  <Text style={{color:palette.text,fontSize:32,fontWeight:"800",letterSpacing:-1}}>Настройки</Text>
  <View style={{flexDirection:"row",alignItems:"center",gap:13,padding:16,backgroundColor:palette.surface,borderRadius:20,borderWidth:1,borderColor:palette.line,marginTop:22,marginBottom:28}}><View style={{width:52,height:52,borderRadius:17,backgroundColor:palette.elevated,alignItems:"center",justifyContent:"center"}}><Ionicons name="pulse" size={28} color={palette.accent}/></View><View><Text style={{color:palette.text,fontSize:18,fontWeight:"800"}}>Rhythm</Text><Text style={{color:palette.muted,fontSize:12,marginTop:3}}>Твой ритм. Твоя музыка.</Text></View></View>
  <Text style={{color:palette.muted,fontSize:11,letterSpacing:1.5,marginBottom:12}}>ВНЕШНИЙ ВИД</Text>
  <View style={{padding:15,borderRadius:18,backgroundColor:palette.surface,borderWidth:1,borderColor:palette.line}}>
   <Text style={{color:palette.text,fontSize:15,fontWeight:"700",marginBottom:12}}>Тема оформления</Text>
   {modes.map(mode=><Pressable key={mode.id} onPress={()=>setAppearance(mode.id)} style={{flexDirection:"row",alignItems:"center",paddingVertical:12,gap:11}}><Ionicons name={mode.icon} size={20} color={appearance===mode.id?palette.accent:palette.muted}/><Text style={{color:palette.text,flex:1}}>{mode.label}</Text><Ionicons name={appearance===mode.id?"radio-button-on":"radio-button-off"} size={20} color={appearance===mode.id?palette.accent:palette.muted}/></Pressable>)}
  </View>
  <View style={{padding:15,borderRadius:18,backgroundColor:palette.surface,borderWidth:1,borderColor:palette.line,marginTop:14}}>
   <Text style={{color:palette.text,fontSize:15,fontWeight:"700"}}>Акцентный цвет</Text><Text style={{color:palette.muted,fontSize:12,marginTop:4,marginBottom:16}}>Меняет подсветку и активные элементы</Text>
   <View style={{flexDirection:"row",justifyContent:"space-between"}}>{ACCENTS.map(item=><Pressable key={item.value} accessibilityLabel={item.name} onPress={()=>setAccent(item.value)} style={{width:43,height:43,borderRadius:22,backgroundColor:item.value,alignItems:"center",justifyContent:"center",borderWidth:accent===item.value?3:0,borderColor:palette.text}}>{accent===item.value&&<Ionicons name="checkmark" size={19} color="#101018"/>}</Pressable>)}</View>
  </View>
  <View style={{padding:15,borderRadius:18,backgroundColor:palette.surface,borderWidth:1,borderColor:palette.line,marginTop:14,gap:13}}>
   {[["musical-notes-outline","Качество звука","Появится после подключения источника"],["notifications-outline","Уведомления","Будут доступны позже"],["information-circle-outline","О приложении","Rhythm · ранний прототип"]].map(([icon,title,sub])=><View key={title} style={{flexDirection:"row",gap:12,alignItems:"center"}}><Ionicons name={icon as any} size={20} color={palette.accent}/><View style={{flex:1}}><Text style={{color:palette.text,fontWeight:"600"}}>{title}</Text><Text style={{color:palette.muted,fontSize:11,marginTop:3}}>{sub}</Text></View></View>)}
  </View>
  <Text style={{color:palette.muted,fontSize:11,textAlign:"center",marginTop:22}}>Настройки темы и акцента сохраняются на устройстве.</Text>
 </ScrollView>;
}
