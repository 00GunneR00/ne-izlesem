import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { bodyFont, colors, headingFont } from "../theme";

export const Background: React.FC = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(1200px 800px at 78% 50%, rgba(211,47,47,0.20), transparent 60%),
        radial-gradient(900px 700px at 0% 100%, rgba(244,182,168,0.07), transparent 60%),
        ${colors.bg}`,
    }}
  />
);

const useEnter = (delay: number) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config: { damping: 200 } });
};

const Bullet: React.FC<{ text: string; index: number }> = ({ text, index }) => {
  const p = useEnter(18 + index * 7);
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 18,
        opacity: p,
        transform: `translateX(${interpolate(p, [0, 1], [-30, 0])}px)`,
        fontFamily: bodyFont,
        fontSize: 30,
        color: colors.text,
        lineHeight: 1.35,
      }}
    >
      <div
        style={{
          width: 12,
          height: 12,
          borderRadius: 6,
          background: colors.primary,
          boxShadow: `0 0 18px ${colors.primary}`,
          flexShrink: 0,
        }}
      />
      {text}
    </div>
  );
};

/** Left: numbered feature title + bullets. Right: whatever phones the scene shows. */
export const FeatureScene: React.FC<{
  step: string;
  title: string;
  description: string;
  bullets: string[];
  children: React.ReactNode;
}> = ({ step, title, description, bullets, children }) => {
  const head = useEnter(0);
  const phones = useEnter(6);

  return (
    <AbsoluteFill>
      <Background />
      <AbsoluteFill style={{ flexDirection: "row", alignItems: "center" }}>
        <div
          style={{
            width: 860,
            paddingLeft: 140,
            display: "flex",
            flexDirection: "column",
            gap: 28,
          }}
        >
          <div
            style={{
              opacity: head,
              transform: `translateY(${interpolate(head, [0, 1], [24, 0])}px)`,
            }}
          >
            <div
              style={{
                fontFamily: headingFont,
                fontWeight: 600,
                fontSize: 24,
                letterSpacing: 6,
                color: colors.primary,
                marginBottom: 18,
              }}
            >
              {step}
            </div>
            <div
              style={{
                fontFamily: headingFont,
                fontWeight: 800,
                fontSize: 76,
                lineHeight: 1.05,
                color: colors.title,
              }}
            >
              {title}
            </div>
            <div
              style={{
                fontFamily: bodyFont,
                fontSize: 30,
                color: colors.muted,
                marginTop: 22,
                lineHeight: 1.45,
              }}
            >
              {description}
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {bullets.map((b, i) => (
              <Bullet key={b} text={b} index={i} />
            ))}
          </div>
        </div>
        <div
          style={{
            flex: 1,
            height: "100%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 36,
            paddingRight: 80,
            opacity: phones,
            transform: `translateY(${interpolate(phones, [0, 1], [80, 0])}px)`,
          }}
        >
          {children}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/** Delays a child's appearance inside a scene (for multi-phone layouts). */
export const Appear: React.FC<{ delay: number; children: React.ReactNode }> = ({
  delay,
  children,
}) => {
  const p = useEnter(delay);
  return (
    <div
      style={{
        opacity: p,
        transform: `translateY(${interpolate(p, [0, 1], [60, 0])}px) scale(${interpolate(p, [0, 1], [0.94, 1])})`,
      }}
    >
      {children}
    </div>
  );
};
