import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { Appear, Background, FeatureScene } from "./components/FeatureScene";
import { Phone } from "./components/Phone";
import { bodyFont, colors, FPS, headingFont, TRANSITION } from "./theme";

const sec = (s: number) => Math.round(s * FPS);

const Title: React.FC<{ size: number; delay?: number }> = ({ size, delay = 0 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ frame: frame - delay, fps, config: { damping: 14, mass: 0.7 } });
  return (
    <div
      style={{
        fontFamily: headingFont,
        fontWeight: 800,
        fontSize: size,
        color: colors.primary,
        transform: `scale(${interpolate(p, [0, 1], [0.8, 1])})`,
        opacity: Math.min(1, p * 1.5),
        textShadow: "0 0 60px rgba(211,47,47,0.45)",
        whiteSpace: "nowrap",
      }}
    >
      Ne İzlesem?
    </div>
  );
};

const FadeUp: React.FC<{ delay: number; children: React.ReactNode; style?: React.CSSProperties }> = ({
  delay,
  children,
  style,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ frame: frame - delay, fps, config: { damping: 200 } });
  return (
    <div style={{ opacity: p, transform: `translateY(${interpolate(p, [0, 1], [24, 0])}px)`, ...style }}>
      {children}
    </div>
  );
};

const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const fan = (i: number) => spring({ frame: frame - 10 - i * 6, fps, config: { damping: 200 } });
  const shots = ["shots/discover.png", "shots/swipe.png", "shots/social.png"];

  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill style={{ flexDirection: "row", alignItems: "center" }}>
        <div style={{ paddingLeft: 140, width: 900 }}>
          <Title size={120} />
          <FadeUp delay={14}>
            <div style={{ fontFamily: headingFont, fontWeight: 600, fontSize: 44, color: colors.title, marginTop: 16 }}>
              Bu akşam ne izlesem?
            </div>
          </FadeUp>
          <FadeUp delay={22}>
            <div style={{ fontFamily: bodyFont, fontSize: 30, color: colors.muted, marginTop: 20, lineHeight: 1.5 }}>
              Kaydır, keşfet, arkadaşlarınla birlikte karar ver.
              <br />
              Film ve diziler için sosyal öneri uygulaması.
            </div>
          </FadeUp>
        </div>
        <div style={{ flex: 1, position: "relative", height: "100%" }}>
          {shots.map((s, i) => {
            const p = fan(i);
            const angle = (i - 1) * 9;
            return (
              <div
                key={s}
                style={{
                  position: "absolute",
                  left: "50%",
                  top: "50%",
                  zIndex: i === 1 ? 2 : 1,
                  opacity: p,
                  transform: `translate(-50%, -50%) translateX(${(i - 1) * 250}px) translateY(${
                    interpolate(p, [0, 1], [140, 0]) + Math.abs(i - 1) * 40
                  }px) rotate(${angle * p}deg)`,
                }}
              >
                <Phone image={s} height={i === 1 ? 820 : 720} />
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const DETAIL_SWAP = sec(5.5);

const DetailPhone: React.FC = () => {
  const frame = useCurrentFrame();
  const swap = interpolate(frame, [DETAIL_SWAP, DETAIL_SWAP + 12], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div style={{ position: "relative" }}>
      <Phone video="clips/detail.mp4" trimBefore={sec(2.5)} height={900} style={{ opacity: 1 - swap }} />
      <Phone image="shots/comments.png" height={900} style={{ position: "absolute", inset: 0, opacity: swap }} />
    </div>
  );
};

const Outro: React.FC = () => {
  const stack = ["Flutter", "GetX", "ASP.NET Core", "PostgreSQL", "Docker", "TMDB API"];
  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
        <Title size={140} />
        <FadeUp delay={12}>
          <div style={{ fontFamily: headingFont, fontWeight: 600, fontSize: 42, color: colors.title, marginTop: 10, textAlign: "center" }}>
            Ne izleyeceğine birlikte karar verin.
          </div>
        </FadeUp>
        <FadeUp delay={22} style={{ display: "flex", gap: 18, marginTop: 56 }}>
          {stack.map((t) => (
            <div
              key={t}
              style={{
                fontFamily: bodyFont,
                fontWeight: 500,
                fontSize: 26,
                color: colors.text,
                padding: "14px 28px",
                borderRadius: 999,
                background: colors.surface,
                border: `2px solid ${colors.surfaceBorder}`,
              }}
            >
              {t}
            </div>
          ))}
        </FadeUp>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

type Scene = { duration: number; node: React.ReactNode };

export const scenes: Scene[] = [
  { duration: sec(3.5), node: <Intro /> },
  {
    duration: sec(10),
    node: (
      <FeatureScene
        step="01 · SWIPE"
        title="Kaydır, karar ver"
        description="Film ve dizileri kart kart geç. Beğendiğin türlere göre öneriler gelir."
        bullets={["Sola kaydır: ilgilenmiyorum", "Sağa kaydır: izledim", "Yer imi: izleyeceklerime ekle", "Film / Dizi arasında geçiş"]}
      >
        <Phone video="clips/swipe.mp4" trimBefore={sec(0.3)} playbackRate={1.2} height={900} />
      </FeatureScene>
    ),
  },
  {
    duration: sec(7),
    node: (
      <FeatureScene
        step="02 · KEŞFET"
        title="Fragmanlarla keşfet"
        description="Dikey akışta yeni ve popüler yapımları kaydırarak gez."
        bullets={["Türe göre filtrele", "Fragmanı uygulama içinde izle", "Beğen ya da listene ekle"]}
      >
        <Phone video="clips/discover.mp4" trimBefore={sec(0.5)} height={900} />
      </FeatureScene>
    ),
  },
  {
    duration: sec(8.5),
    node: (
      <FeatureScene
        step="03 · DETAY"
        title="Her şey tek sayfada"
        description="Özet, oyuncular, fragman ve arkadaşlarının yorumları."
        bullets={["İzledim / İzleyeceğim tek dokunuşla", "Oyuncu kadrosu ve fragman", "Yorum yaz, yorumları oku"]}
      >
        <DetailPhone />
      </FeatureScene>
    ),
  },
  {
    duration: sec(8),
    node: (
      <FeatureScene
        step="04 · ARAMA"
        title="İstediğin gibi ara"
        description="Adına, oyuncusuna ya da üye olduğun platforma göre bul."
        bullets={["Film ve dizi adıyla arama", "Oyuncunun tüm filmografisi", "Netflix, Prime, Disney+ ve daha fazlası"]}
      >
        <Phone video="clips/search.mp4" trimBefore={sec(2.5)} height={640} />
        <Appear delay={sec(2)}>
          <Phone image="shots/filmography.png" height={640} />
        </Appear>
        <Appear delay={sec(3.5)}>
          <Phone image="shots/platform.png" height={640} />
        </Appear>
      </FeatureScene>
    ),
  },
  {
    duration: sec(9.5),
    node: (
      <FeatureScene
        step="05 · SOSYAL"
        title="Arkadaşların ne izliyor?"
        description="Arkadaşlarının beğenilerini ve yorumlarını akışta gör."
        bullets={["Arkadaş akışı", "Genel trendler", "Tek dokunuşla listene ekle"]}
      >
        <Phone video="clips/social.mp4" trimBefore={sec(2.5)} playbackRate={1.3} height={900} />
      </FeatureScene>
    ),
  },
  {
    duration: sec(7),
    node: (
      <FeatureScene
        step="06 · ÖNERİ & GRUPLAR"
        title="Birlikte karar verin"
        description="Bir yapımı arkadaşlarına ya da grubuna öner, onaylananlar grup listesine düşsün."
        bullets={["Arkadaşa veya gruba öner", "Bildirimden kabul et ya da geç", "Grubun ortak izleme listesi"]}
      >
        <Phone image="shots/suggest.png" height={640} />
        <Appear delay={sec(1.2)}>
          <Phone image="shots/notifications.png" height={640} />
        </Appear>
        <Appear delay={sec(2.4)}>
          <Phone image="shots/group.png" height={640} />
        </Appear>
      </FeatureScene>
    ),
  },
  {
    duration: sec(6),
    node: (
      <FeatureScene
        step="07 · KÜTÜPHANE"
        title="Senin listen, senin arşivin"
        description="İzlediklerin ve izleyeceklerin tek yerde; arkadaşlarını kodla ekle."
        bullets={["İzlediklerim / İzleyeceklerim", "Film ve dizi filtreleri", "Arkadaş kodu ile ekleme"]}
      >
        <Phone image="shots/library.png" height={800} />
        <Appear delay={sec(1)}>
          <Phone image="shots/friends.png" height={800} />
        </Appear>
      </FeatureScene>
    ),
  },
  { duration: sec(4.5), node: <Outro /> },
];

export const totalDuration =
  scenes.reduce((sum, s) => sum + s.duration, 0) - TRANSITION * (scenes.length - 1);

export const Showcase: React.FC = () => (
  <AbsoluteFill style={{ background: colors.bg }}>
    <TransitionSeries>
      {scenes.map((s, i) => (
        <React.Fragment key={i}>
          {i > 0 && (
            <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: TRANSITION })} />
          )}
          <TransitionSeries.Sequence durationInFrames={s.duration}>{s.node}</TransitionSeries.Sequence>
        </React.Fragment>
      ))}
    </TransitionSeries>
  </AbsoluteFill>
);
