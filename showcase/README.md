# Ne İzlesem? — Tanıtım Videosu

Uygulamanın özelliklerini anlatan ~60 saniyelik tanıtım videosu. [Remotion](https://www.remotion.dev/) ile hazırlandı; telefon görüntüleri gerçek cihazdan alınmış kayıtlardır.

## Kullanım

```bash
cd showcase
npm install
npm run studio   # tarayıcıda önizleme ve düzenleme
npm run render   # out/neizlesem-tanitim.mp4 dosyasını üretir (1920x1080, 30 fps)
```

## Instagram / TikTok videoları

`src/reels/` altında her özellik için 1080x1920 dikey bir video var. Her biri izleyicinin yaşadığı bir sorunla (kanca) açılır, ardından uygulamanın o sorunu nasıl çözdüğünü gösterir.

```bash
npx remotion render Reel01-Swipe out/reels/Reel01-Swipe.mp4
```

Kompozisyonlar: `Reel01-Swipe`, `Reel02-Kesfet`, `Reel03-Oyuncu`, `Reel04-Platform`, `Reel05-Sosyal`, `Reel06-Grup`, `Reel07-Kutuphane`.
Metinler `src/reels/reels.ts` içinde (`*yıldız*` arasındaki kelimeler vurgulanır); kapanış çağrısı `src/reels/Reel.tsx` içindeki `CTA_ACTION`.
Videolarda ses yok; paylaşırken platformun trend müziklerinden birini eklemek erişimi artırır.

## Yapı

- `src/Showcase.tsx` — sahneler, metinler ve süreler
- `src/components/Phone.tsx` — telefon çerçevesi (ekran görüntüsü veya video)
- `src/components/FeatureScene.tsx` — başlık + madde listesi + telefon düzeni
- `public/clips/` — cihazdan alınan ekran kayıtları (`adb shell screenrecord`)
- `public/shots/` — cihazdan alınan ekran görüntüleri (`adb shell screencap`)

Sahne sırası: Giriş → Swipe → Keşfet → Detay → Arama → Sosyal → Öneri & Gruplar → Kütüphane → Kapanış.
