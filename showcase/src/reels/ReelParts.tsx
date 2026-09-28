import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { bodyFont, colors, headingFont } from "../theme";

// Vertical 1080x1920. TikTok/Reels overlay their own UI on the bottom ~22%
// and the right edge, so all text stays in the top/center safe area.
export const SAFE_X = 90;

export const ReelBackground: React.FC<{ intensity?: number }> = ({ intensity = 1 }) => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(900px 900px at 50% 38%, rgba(211,47,47,${0.28 * intensity}), transparent 65%),
        radial-gradient(700px 600px at 10% 95%, rgba(244,182,168,0.08), transparent 60%),
        ${colors.bg}`,
    }}
  />
);

const useSpring = (delay: number, damping = 200) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config: { damping } });
};

/** Big hook text: words pop in one by one; words wrapped in *stars* are highlighted. */
export const HookText: React.FC<{ text: string; size?: number; delay?: number }> = ({
  text,
  size = 92,
  delay = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // "*1 saat*" highlights every word between the stars, not just the first.
  let inHighlight = false;
  const words = text.split(" ").map((raw) => {
    const opens = raw.startsWith("*");
    if (opens) inHighlight = true;
    const highlight = inHighlight;
    if (raw.endsWith("*") && (raw.length > 1 || !opens)) inHighlight = false;
    return { word: raw.replace(/\*/g, ""), highlight };
  });
  return (
    <div
      style={{
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: `${size * 0.12}px ${size * 0.26}px`,
        padding: `0 ${SAFE_X}px`,
        textAlign: "center",
      }}
    >
      {words.map(({ word, highlight }, i) => {
        // Offset so most of the hook is already readable on frame 0 — platforms use it as the cover image.
        const p = spring({ frame: frame + 16 - delay - i * 2, fps, config: { damping: 12, mass: 0.6 } });
        return (
          <span
            key={i}
            style={{
              fontFamily: headingFont,
              fontWeight: 800,
              fontSize: size,
              lineHeight: 1.08,
              color: highlight ? "#fff" : colors.text,
              background: highlight ? colors.primary : "transparent",
              padding: highlight ? `0 ${size * 0.16}px` : 0,
              borderRadius: size * 0.14,
              display: "inline-block",
              opacity: Math.min(1, p * 2),
              transform: `translateY(${interpolate(p, [0, 1], [size * 0.6, 0])}px) scale(${interpolate(p, [0, 1], [0.7, 1])})`,
              textShadow: highlight ? "none" : "0 6px 30px rgba(0,0,0,0.6)",
            }}
          >
            {word}
          </span>
        );
      })}
    </div>
  );
};

/** Small line under the hook, e.g. "Tanıdık geldi mi?" */
export const SubLine: React.FC<{ text: string; delay: number; size?: number; color?: string }> = ({
  text,
  delay,
  size = 48,
  color = colors.title,
}) => {
  const p = useSpring(delay);
  return (
    <div
      style={{
        fontFamily: bodyFont,
        fontWeight: 600,
        fontSize: size,
        color,
        textAlign: "center",
        padding: `0 ${SAFE_X}px`,
        opacity: p,
        transform: `translateY(${interpolate(p, [0, 1], [30, 0])}px)`,
        lineHeight: 1.3,
      }}
    >
      {text}
    </div>
  );
};

/** Caption pill shown above the phone during the solution part. */
export const Caption: React.FC<{ text: string; size?: number }> = ({ text, size = 54 }) => {
  const p = useSpring(0, 14);
  return (
    <div
      style={{
        display: "inline-block",
        fontFamily: headingFont,
        fontWeight: 800,
        fontSize: size,
        color: "#fff",
        background: colors.primary,
        padding: "18px 36px",
        borderRadius: 28,
        boxShadow: "0 18px 50px rgba(211,47,47,0.45)",
        transform: `scale(${interpolate(p, [0, 1], [0.6, 1])})`,
        opacity: Math.min(1, p * 2),
        textAlign: "center",
        maxWidth: 1080 - SAFE_X * 2,
        lineHeight: 1.15,
      }}
    >
      {text}
    </div>
  );
};

/** Simple emoji-free "relatable" chat bubble used in hook scenes. */
export const Bubble: React.FC<{ text: string; delay: number; side: "left" | "right"; name?: string }> = ({
  text,
  delay,
  side,
  name,
}) => {
  const p = useSpring(delay, 16);
  const mine = side === "right";
  return (
    <div
      style={{
        alignSelf: mine ? "flex-end" : "flex-start",
        maxWidth: 720,
        opacity: Math.min(1, p * 2),
        transform: `translateY(${interpolate(p, [0, 1], [40, 0])}px) scale(${interpolate(p, [0, 1], [0.85, 1])})`,
        transformOrigin: mine ? "right bottom" : "left bottom",
      }}
    >
      {name && (
        <div style={{ fontFamily: bodyFont, fontSize: 30, color: colors.muted, margin: "0 0 8px 20px" }}>{name}</div>
      )}
      <div
        style={{
          fontFamily: bodyFont,
          fontWeight: 500,
          fontSize: 44,
          lineHeight: 1.3,
          color: mine ? "#fff" : colors.text,
          background: mine ? colors.primary : colors.surface,
          border: mine ? "none" : `2px solid ${colors.surfaceBorder}`,
          padding: "22px 32px",
          borderRadius: mine ? "36px 36px 8px 36px" : "36px 36px 36px 8px",
        }}
      >
        {text}
      </div>
    </div>
  );
};

/** Closing call to action. */
export const CTA: React.FC<{ line: string; action: string }> = ({ line, action }) => {
  const p = useSpring(0, 13);
  const q = useSpring(10);
  const frame = useCurrentFrame();
  const pulse = 1 + Math.sin(frame / 5) * 0.025;
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", paddingBottom: 260 }}>
      <ReelBackground intensity={1.3} />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 40 }}>
        <div
          style={{
            fontFamily: headingFont,
            fontWeight: 800,
            fontSize: 130,
            color: colors.primary,
            textShadow: "0 0 70px rgba(211,47,47,0.5)",
            transform: `scale(${interpolate(p, [0, 1], [0.7, 1])})`,
            opacity: Math.min(1, p * 2),
            whiteSpace: "nowrap",
          }}
        >
          Ne İzlesem?
        </div>
        <div style={{ opacity: q, transform: `translateY(${interpolate(q, [0, 1], [30, 0])}px)` }}>
          <SubLine text={line} delay={0} size={52} color={colors.text} />
        </div>
        <div
          style={{
            opacity: q,
            transform: `scale(${pulse})`,
            fontFamily: headingFont,
            fontWeight: 800,
            fontSize: 50,
            color: "#fff",
            background: colors.primary,
            padding: "26px 60px",
            borderRadius: 999,
            boxShadow: "0 20px 60px rgba(211,47,47,0.5)",
            marginTop: 10,
          }}
        >
          {action}
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Gentle Ken Burns motion for still screenshots so they don't feel static. */
export const Drift: React.FC<{ children: React.ReactNode; from?: number; to?: number; y?: number }> = ({
  children,
  from = 1,
  to = 1.06,
  y = -30,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const t = interpolate(frame, [0, durationInFrames], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div style={{ transform: `scale(${interpolate(t, [0, 1], [from, to])}) translateY(${t * y}px)` }}>{children}</div>
  );
};
