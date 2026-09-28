import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  Series,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { Phone } from "../components/Phone";
import { FPS } from "../theme";
import { Bubble, Caption, CTA, Drift, HookText, ReelBackground, SAFE_X, SubLine } from "./ReelParts";

export const sec = (s: number) => Math.round(s * FPS);

export type StepMedia =
  | { image: string; zoom?: [number, number]; drift?: number }
  | { video: string; from: number; playbackRate?: number };

export type Step = { caption: string; seconds: number; media: StepMedia };

export type ReelSpec = {
  id: string;
  /** Screenshot blurred behind the hook text. */
  backdrop: string;
  hook: string;
  sub: string;
  /** Optional chat bubbles shown before the hook text (relatable conversation). */
  chat?: { text: string; side: "left" | "right"; name?: string }[];
  steps: Step[];
  ctaLine: string;
};

export const CTA_ACTION = "Takip et, ilk sen dene";
const HOOK_SECONDS = 3;
const CHAT_SECONDS = 3.6;
const CTA_SECONDS = 2.6;
const FADE = 8;
// Caption sits below TikTok's top tabs; phone ends above the bottom caption/UI zone.
const CAPTION_TOP = 220;
const PHONE_TOP = 380;
const PHONE_H = 1110;

const Backdrop: React.FC<{ src: string }> = ({ src }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      <Img
        src={staticFile(src)}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          filter: "blur(22px) saturate(1.3)",
          opacity: 0.55,
          transform: `scale(${1.15 + frame * 0.0015})`,
        }}
      />
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(10,8,8,0.35), rgba(10,8,8,0.6) 45%, rgba(10,8,8,0.92))" }} />
    </AbsoluteFill>
  );
};

const HookScene: React.FC<{ spec: ReelSpec }> = ({ spec }) => (
  <AbsoluteFill>
    <ReelBackground />
    <Backdrop src={spec.backdrop} />
    <AbsoluteFill style={{ justifyContent: "center", paddingBottom: 300, gap: 50 }}>
      <HookText text={spec.hook} />
      <SubLine text={spec.sub} delay={sec(1.1)} />
    </AbsoluteFill>
  </AbsoluteFill>
);

const ChatScene: React.FC<{ chat: NonNullable<ReelSpec["chat"]>; backdrop: string }> = ({ chat, backdrop }) => {
  const step = sec(CHAT_SECONDS - 0.6) / chat.length;
  return (
    <AbsoluteFill>
      <ReelBackground />
      <Backdrop src={backdrop} />
      <AbsoluteFill
        style={{ justifyContent: "center", padding: `0 ${SAFE_X}px 320px`, display: "flex", flexDirection: "column", gap: 28 }}
      >
        {chat.map((m, i) => (
          <Bubble key={i} text={m.text} side={m.side} name={m.name} delay={Math.round(i * step)} />
        ))}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const StepScene: React.FC<{ step: Step; enter: boolean }> = ({ step, enter }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = enter ? spring({ frame, fps, config: { damping: 200 } }) : 1;
  const m = step.media;
  const phone =
    "image" in m ? (
      <Drift from={m.zoom?.[0] ?? 1} to={m.zoom?.[1] ?? 1.05} y={m.drift ?? -20}>
        <Phone image={m.image} height={PHONE_H} />
      </Drift>
    ) : (
      <Phone video={m.video} trimBefore={sec(m.from)} playbackRate={m.playbackRate} height={PHONE_H} />
    );

  return (
    <AbsoluteFill>
      <ReelBackground />
      <AbsoluteFill style={{ alignItems: "center" }}>
        <div style={{ position: "absolute", top: CAPTION_TOP, width: "100%", display: "flex", justifyContent: "center" }}>
          <Caption key={step.caption} text={step.caption} />
        </div>
        <div
          style={{
            position: "absolute",
            top: PHONE_TOP,
            opacity: p,
            transform: `translateY(${interpolate(p, [0, 1], [200, 0])}px)`,
          }}
        >
          {phone}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Solution: React.FC<{ steps: Step[] }> = ({ steps }) => (
  <Series>
    {steps.map((s, i) => (
      <Series.Sequence key={i} durationInFrames={sec(s.seconds)}>
        <StepScene step={s} enter={i === 0} />
      </Series.Sequence>
    ))}
  </Series>
);

const parts = (spec: ReelSpec) => {
  const list: { frames: number; node: React.ReactNode }[] = [];
  if (spec.chat) list.push({ frames: sec(CHAT_SECONDS), node: <ChatScene chat={spec.chat} backdrop={spec.backdrop} /> });
  list.push({ frames: sec(HOOK_SECONDS), node: <HookScene spec={spec} /> });
  list.push({
    frames: spec.steps.reduce((sum, s) => sum + sec(s.seconds), 0),
    node: <Solution steps={spec.steps} />,
  });
  list.push({ frames: sec(CTA_SECONDS), node: <CTA line={spec.ctaLine} action={CTA_ACTION} /> });
  return list;
};

export const reelDuration = (spec: ReelSpec) => {
  const p = parts(spec);
  return p.reduce((sum, x) => sum + x.frames, 0) - FADE * (p.length - 1);
};

export const Reel: React.FC<{ spec: ReelSpec }> = ({ spec }) => (
  <AbsoluteFill style={{ background: "#0A0808" }}>
    <TransitionSeries>
      {parts(spec).map((x, i) => (
        <React.Fragment key={i}>
          {i > 0 && <TransitionSeries.Transition presentation={fade()} timing={linearTiming({ durationInFrames: FADE })} />}
          <TransitionSeries.Sequence durationInFrames={x.frames}>{x.node}</TransitionSeries.Sequence>
        </React.Fragment>
      ))}
    </TransitionSeries>
  </AbsoluteFill>
);
