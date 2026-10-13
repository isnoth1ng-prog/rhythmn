export type Track = { id: string; title: string; artist: string; album: string; duration: number; art: string; source: string; audioUrl?: string; demo?: boolean };
export const SAMPLE_TRACK: Track = {
  id: "sample-scarborough", title: "Scarborough Fair", artist: "Traditional · recording by Makemi",
  album: "Public-domain folk recording", duration: 168,
  art: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1000&q=85",
  source: "Wikimedia Commons · CC BY-SA 3.0 / GFDL",
  audioUrl: "https://upload.wikimedia.org/wikipedia/commons/transcoded/a/a4/Scarborough_Fair.ogg/Scarborough_Fair.ogg.mp3",
  demo: true
};
export const STARTER_TRACKS: Track[] = [
  SAMPLE_TRACK,
  { id: "demo-blue-hour", title: "Blue Hour", artist: "Rhythm Sessions", album: "Afterglow", duration: 198, art: "https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=600&q=80", source: "Demo", demo: true },
  { id: "demo-low-tide", title: "Low Tide", artist: "Northbound", album: "Low Tide", duration: 231, art: "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=600&q=80", source: "Demo", demo: true },
  { id: "demo-after-rain", title: "After the Rain", artist: "Mira Vale", album: "Soft Focus", duration: 186, art: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=600&q=80", source: "Demo", demo: true }
];
// The folk song is traditional/public-domain; lyric timing below is approximate UI-test timing, not provider-synchronized metadata.
export const SAMPLE_LYRICS = [
  { time: 0, text: "Are you going to Scarborough Fair?" },
  { time: 18, text: "Parsley, sage, rosemary and thyme" },
  { time: 36, text: "Remember me to one who lives there" },
  { time: 54, text: "She once was a true love of mine" },
  { time: 72, text: "Tell her to make me a cambric shirt" },
  { time: 90, text: "Parsley, sage, rosemary and thyme" },
  { time: 108, text: "Without no seams nor needlework" },
  { time: 126, text: "Then she'll be a true love of mine" }
];
export const formatTime = (seconds: number) => {
  const safe = Math.max(0, Math.floor(seconds));
  return `${Math.floor(safe / 60)}:${String(safe % 60).padStart(2, "0")}`;
};
