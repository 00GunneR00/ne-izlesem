import type { ReelSpec } from "./Reel";

// One short vertical video per feature. Each opens with a relatable problem
// (the hook), then shows how the app solves it. Words in *stars* are highlighted.
export const reels: ReelSpec[] = [
  {
    id: "Reel01-Swipe",
    backdrop: "shots/swipe.png",
    hook: "Netflix'te *40 dakika* gezip hiçbir şey açmadan uyudun mu?",
    sub: "Seçmek, izlemekten uzun sürüyorsa bu video senin için.",
    steps: [
      { caption: "Beğenmedin mi? Sola kaydır", seconds: 3, media: { video: "clips/swipe.mp4", from: 0.3 } },
      { caption: "İzledin mi? Sağa kaydır", seconds: 3.4, media: { video: "clips/swipe.mp4", from: 3.3 } },
      { caption: "Sonra mı? Listene ekle", seconds: 3.4, media: { video: "clips/swipe.mp4", from: 6.8 } },
    ],
    ctaLine: "Kaydır, karar ver. Saniyeler içinde.",
  },
  {
    id: "Reel02-Kesfet",
    backdrop: "shots/discover.png",
    hook: "Bir fragman açtın, *2 saat sonra* hâlâ YouTube'dasın.",
    sub: "Film seçmeye gidip başka bir şeyde kaybolmak...",
    steps: [
      { caption: "Fragmanlar tek akışta", seconds: 3.4, media: { video: "clips/discover.mp4", from: 0.5 } },
      { caption: "Kaydır, yenisi gelsin", seconds: 3.6, media: { video: "clips/discover.mp4", from: 3.9 } },
      { caption: "Aksiyon mu? Tek dokunuş", seconds: 3, media: { video: "clips/discover.mp4", from: 8.6 } },
    ],
    ctaLine: "Fragmanı izle, beğen, listene ekle.",
  },
  {
    id: "Reel03-Oyuncu",
    backdrop: "shots/filmography.png",
    hook: "O filmdeki oyuncunun *başka ne* filmi vardı ya?",
    sub: "Adı dilinin ucunda, Google'da 10 sekme açık...",
    steps: [
      // actor.mp4 4–7s has a system notification banner on screen, so both cuts skip it.
      { caption: "Oyuncuyu seç", seconds: 1.9, media: { video: "clips/actor.mp4", from: 0.4 } },
      { caption: "Tüm filmleri tek ekranda", seconds: 3, media: { video: "clips/actor.mp4", from: 7.9 } },
    ],
    ctaLine: "Sevdiğin oyuncunun her filmi bir dokunuş uzağında.",
  },
  {
    id: "Reel04-Platform",
    backdrop: "shots/platform.png",
    hook: "Her ay para ödüyorsun ama *içinde ne var* bilmiyorsun.",
    sub: "3 abonelik, 0 izlenecek şey. Tanıdık mı?",
    steps: [
      { caption: "Aboneliğin olan platformu seç", seconds: 4, media: { video: "clips/platform.mp4", from: 3.6, playbackRate: 1.3 } },
      { caption: "Film de dizi de, hepsi önünde", seconds: 3.6, media: { video: "clips/platform.mp4", from: 8.3 } },
    ],
    ctaLine: "Netflix, Prime, Disney+, HBO Max, Exxen...",
  },
  {
    id: "Reel05-Sosyal",
    backdrop: "shots/social.png",
    chat: [
      { name: "Mert", text: "Geçen hafta söylediğim filmi izledin mi?", side: "left" },
      { text: "Hangisiydi ya...", side: "right" },
      { name: "Mert", text: "Of, yine mi unuttun", side: "left" },
    ],
    hook: "Arkadaşının önerisini *yine* unuttun.",
    sub: "Adı neydi, kim önermişti, nereye yazmıştın...",
    steps: [
      { caption: "Arkadaşların ne izliyor, gör", seconds: 3.6, media: { video: "clips/social.mp4", from: 2.5, playbackRate: 1.2 } },
      { caption: "Yorumlarını oku", seconds: 2.8, media: { image: "shots/comments.png", zoom: [1, 1.06], drift: -40 } },
      { caption: "Tek dokunuşla listene ekle", seconds: 2.8, media: { image: "shots/social.png", zoom: [1, 1.05] } },
    ],
    ctaLine: "Arkadaşların izliyor, sen de kaçırma.",
  },
  {
    id: "Reel06-Grup",
    backdrop: "shots/notifications.png",
    chat: [
      { name: "Ayşe", text: "Bu akşam ne izliyoruz?", side: "left" },
      { name: "Zeynep", text: "Fark etmez, siz seçin", side: "left" },
      { name: "Mert", text: "Bence de fark etmez", side: "left" },
    ],
    hook: "\"Ne izliyoruz?\" sorusu *1 saat* sürüyor.",
    sub: "Sonunda herkes telefonuna gömülüyor.",
    steps: [
      { caption: "Filmi gruba öner", seconds: 5.6, media: { video: "clips/suggest.mp4", from: 1.8, playbackRate: 1.2 } },
      { caption: "Gelen öneriyi tek dokunuşla kabul et", seconds: 2.8, media: { video: "clips/notify.mp4", from: 2.6 } },
      { caption: "Herkes onayladı, liste hazır", seconds: 3.4, media: { video: "clips/group.mp4", from: 2.4 } },
    ],
    ctaLine: "Arkadaş grubunla saniyede karar verin.",
  },
  {
    id: "Reel07-Kutuphane",
    backdrop: "shots/library.png",
    hook: "Bu diziyi *izlemiş miydim* ya?",
    sub: "3. bölümde anlıyorsun ki zaten izlemişsin...",
    steps: [
      { caption: "Tek dokunuş: İzledim / İzleyeceğim", seconds: 2.6, media: { video: "clips/detail.mp4", from: 0 } },
      { caption: "İzlediklerin tek yerde", seconds: 6, media: { video: "clips/library.mp4", from: 0.5, playbackRate: 1.3 } },
    ],
    ctaLine: "Neyi izledin, neyi izleyeceksin; hepsi burada.",
  },
];
