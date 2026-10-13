import { Track } from "./data";

export type ListeningSignal = {
  likedTrackIds: string[];
  skippedTrackIds: string[];
  recentlyPlayedIds: string[];
  seedTrackId?: string;
  mood?: string;
};
export type RecommendationBatch = {
  tracks: Track[];
  providerName: string;
  isPersonalized: boolean;
};
export interface RecommendationProvider {
  readonly id: string;
  recommendNext(signal: ListeningSignal, count: number): Promise<RecommendationBatch>;
}

// No provider is enabled by default. This avoids disguising a fixed local fixture list as a real radio.
export class ProviderNotConfiguredError extends Error {
  constructor() {
    super("A licensed catalog/recommendation provider has not been configured.");
    this.name = "ProviderNotConfiguredError";
  }
}
export class RecommendationQueue {
  private queue: Track[] = [];
  private seen = new Set<string>();
  constructor(private provider: RecommendationProvider) {}
  async next(signal: ListeningSignal): Promise<Track> {
    if (this.queue.length < 2) {
      const batch = await this.provider.recommendNext(signal, 8);
      const unique = batch.tracks.filter(track => !this.seen.has(track.id) && !signal.recentlyPlayedIds.includes(track.id));
      this.queue.push(...unique);
    }
    const next = this.queue.shift();
    if (!next) throw new ProviderNotConfiguredError();
    this.seen.add(next.id);
    return next;
  }
}
